import vscode, {TextDocument, TextEditor, TextEditorEdit, ViewColumn, WebviewPanel} from "vscode";
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
	console.log('\n\n\nactivate\n\n\n')
	let previewPanel: WebviewPanel | undefined = undefined
	context.subscriptions.push(
		vscode.commands.registerTextEditorCommand('aml.fromJson', (editor: TextEditor, edit: TextEditorEdit) => convertJson(editor, edit)),
		vscode.commands.registerTextEditorCommand('aml.fromSQL', (editor: TextEditor, edit: TextEditorEdit) => convertSql(editor, edit)),
		vscode.commands.registerTextEditorCommand('aml.convert', (editor: TextEditor, edit: TextEditorEdit) => convertAml(editor, edit)),
		vscode.commands.registerTextEditorCommand('aml.preview', (editor: TextEditor, edit: TextEditorEdit) => {
			vscode.window.showInformationMessage('aml.preview called')
			if (editor.document.languageId !== 'aml') {
				vscode.window.showErrorMessage('Needs AML file to preview it.')
				return
			}
			const viewColumn = editor.viewColumn ? editor.viewColumn + 1 : ViewColumn.Two
			if (!previewPanel) {
				previewPanel = vscode.window.createWebviewPanel('aml-preview', 'Preview AML', {viewColumn, preserveFocus: true}, {localResourceRoots: []})
				previewPanel.onDidDispose(() => previewPanel = undefined, null, context.subscriptions)
			}
			updateAmlPreview(editor.document, previewPanel, viewColumn)
			// TODO: update preview when editor text changes or when editor changes to another aml (with debounce)
			// vscode.window.onDidChangeActiveTextEditor((editor: TextEditor) => {})
		})
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

function updateAmlPreview(doc: TextDocument, panel: WebviewPanel, col: ViewColumn) {
	panel.title = 'Preview ' + doc.fileName
	panel.webview.html = buildAmlPreview(doc.getText())
	if (panel.viewColumn !== col) {
		panel.reveal(col)
	}
}

function buildAmlPreview(aml: string): string {
	return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AML preview</title>
</head>
<body>
    <pre>${aml}</pre>
</body>
</html>`;
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
		default: return '[ERR] '
	}
}
