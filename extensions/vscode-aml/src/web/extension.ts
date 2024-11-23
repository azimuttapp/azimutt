import vscode, {TextDocument, TextEditor, TextEditorEdit} from "vscode";
import {ParserError, ParserErrorLevel} from "@azimutt/models";
import {generateSql, parseSql} from "@azimutt/parser-sql";
import {
	Database,
	generateAml,
	generateDot,
	generateJsonDatabase,
	generateMarkdown,
	generateMermaid,
	parseAml,
	parseJsonDatabase,
	ParserResult
} from "@azimutt/aml";

export function activate(context: vscode.ExtensionContext) {
	context.subscriptions.push(
		vscode.commands.registerTextEditorCommand('vscode-aml.fromJson', (editor: TextEditor, edit: TextEditorEdit) => convertJson(editor, edit)),
		vscode.commands.registerTextEditorCommand('vscode-aml.fromSQL', (editor: TextEditor, edit: TextEditorEdit) => convertSql(editor, edit)),
		vscode.commands.registerTextEditorCommand('vscode-aml.convert', (editor: TextEditor, edit: TextEditorEdit) => convertAml(editor, edit))
	)
}

export function deactivate() {}

// private functions

async function convertJson(editor: TextEditor, edit: TextEditorEdit): Promise<void> {
	if (editor.document.languageId !== 'json') {
		vscode.window.showErrorMessage('Needs JSON file to convert it to AML.')
		return
	}

	const res = parseJsonDatabase(editor.document.getText())
	const error = formatErrors(res.errors)
	const db = res.result

	if (db) {
		error && vscode.window.showWarningMessage(error)
		await openFile('aml', generateAml(db))
	} else {
		error && vscode.window.showErrorMessage(error)
	}
}

async function convertSql(editor: TextEditor, edit: TextEditorEdit): Promise<void> {
	if (editor.document.languageId !== 'sql') {
		vscode.window.showErrorMessage('Needs SQL file to convert it to AML.')
		return
	}

	const dialects = ['PostgreSQL']
	const dialect = await vscode.window.showQuickPick(dialects, {placeHolder: 'Select target'})
	if (dialect === 'PostgreSQL') {
		await writeAml(parseSql(editor.document.getText(), 'postgres'))
	} else {
		vscode.window.showWarningMessage(`Unable to convert SQL to AML: unsupported ${dialect} dialect.`)
	}
}

async function writeAml(res: ParserResult<Database>): Promise<void> {
	const error = formatErrors(res.errors)
	const db = res.result
	if (db) {
		error && vscode.window.showWarningMessage(error)
		await openFile('aml', generateAml(db))
	} else {
		error && vscode.window.showErrorMessage(error)
	}
}

async function convertAml(editor: TextEditor, edit: TextEditorEdit): Promise<void> {
	if (editor.document.languageId !== 'aml') {
		vscode.window.showErrorMessage('Needs AML file to convert AML to another language.')
		return
	}

	const dialects = ['PostgreSQL', 'JSON', 'DOT', 'Mermaid', 'Markdown']
	const dialect = await vscode.window.showQuickPick(dialects, {placeHolder: 'Select target'})
	const res = parseAml(editor.document.getText())
	const error = formatErrors(res.errors)
	const db = res.result

	if (db) {
		error && vscode.window.showWarningMessage(error)
		if (dialect === 'JSON') {
			await openFile('json', generateJsonDatabase(db))
		} else if (dialect === 'DOT') {
			await openFile('dot', generateDot(db))
		} else if (dialect === 'Mermaid') {
			await openFile('mermaid', generateMermaid(db))
		} else if (dialect === 'Markdown') {
			await openFile('markdown', generateMarkdown(db))
		} else if (dialect === 'PostgreSQL') {
			await openFile('sql', generateSql(db, 'postgres'))
		} else {
			vscode.window.showWarningMessage(`Unable to convert AML to ${dialect}: unsupported dialect.`)
		}
	} else {
		error && vscode.window.showErrorMessage(error)
	}
}

async function openFile(lang: string, content: string): Promise<TextDocument> {
	const doc: TextDocument = await vscode.workspace.openTextDocument({language: lang, content: content})
	await vscode.window.showTextDocument(doc)
	return doc
}

function formatErrors(errors: ParserError[] | undefined): string | undefined {
	if (errors && errors.length > 1) {
		return `Got ${errors.length} AML parsing issues:${errors.map(e => `\n- ${formatErrorLevel(e.level)} ${e.message}`).join('')}`
	} else if (errors && errors.length === 1) {
		const error = errors[0]
		return `AML parsing ${error.level}: ${error.message}`
	} else {
		return undefined
	}
}

function formatErrorLevel(level: ParserErrorLevel): string {
	switch (level) {
		case 'error': return '[ERR] '
		case 'warning': return '[WARN]'
		case 'info': return '[INFO]'
		case 'hint': return '[HINT]'
	}
}
