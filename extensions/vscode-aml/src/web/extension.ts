import vscode, {
	ExtensionContext,
	TextDocument,
	TextDocumentChangeEvent,
	TextEditor,
	ViewColumn,
	WebviewPanel
} from "vscode";
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

let previewPanel: WebviewPanel | undefined = undefined

export function activate(context: ExtensionContext) {
	console.log('\n\n\nactivate\n\n\n')
	context.subscriptions.push(
		vscode.commands.registerTextEditorCommand('aml.fromJson', (editor: TextEditor) => convertJsonToAml(editor)),
		vscode.commands.registerTextEditorCommand('aml.fromSQL', (editor: TextEditor) => convertSqlToAml(editor)),
		vscode.commands.registerTextEditorCommand('aml.convert', (editor: TextEditor) => convertAmlToDialect(editor)),
		vscode.commands.registerTextEditorCommand('aml.preview', (editor: TextEditor) => previewAml(editor, context))
	)
}

export function deactivate() {}

// private functions

async function convertJsonToAml(editor: TextEditor): Promise<void> {
	if (editor.document.languageId !== 'json') {
		vscode.window.showErrorMessage('Needs JSON file to convert it to AML.')
		return
	}

	await openFileResult(parseJsonDatabase(editor.document.getText()).map((db: Database) => ({lang: 'aml', content: generateAml(db)})))
}

async function convertSqlToAml(editor: TextEditor): Promise<void> {
	if (editor.document.languageId !== 'sql') {
		vscode.window.showErrorMessage('Needs SQL file to convert it to AML.')
		return
	}

	const dialects = ['PostgreSQL']
	const dialect = await vscode.window.showQuickPick(dialects, {placeHolder: 'Select target'})
	if (dialect === 'PostgreSQL') {
		await openFileResult(parseSql(editor.document.getText(), 'postgres').map((db: Database) => ({lang: 'aml', content: generateAml(db)})))
	} else {
		vscode.window.showWarningMessage(`Unable to convert SQL to AML: unsupported ${dialect} dialect.`)
	}
}

async function convertAmlToDialect(editor: TextEditor): Promise<void> {
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

function previewAml(editor: TextEditor, context: ExtensionContext) {
	vscode.window.showInformationMessage('previewAml called')
	if (editor.document.languageId !== 'aml') {
		vscode.window.showErrorMessage('Needs AML file to preview it.')
		return
	}
	if (!previewPanel) {
		previewPanel = vscode.window.createWebviewPanel('aml-preview', 'Preview AML', {viewColumn: ViewColumn.Beside, preserveFocus: true}, {localResourceRoots: []})
		const subscriptions = [
			vscode.workspace.onDidOpenTextDocument((document: TextDocument) => {
				console.log('onDidOpenTextDocument', document.fileName)
				if (document.languageId === 'aml' && previewPanel) {
					updateAmlPreview(document, previewPanel)
				}
			}, null, context.subscriptions),
			vscode.workspace.onDidChangeTextDocument((e: TextDocumentChangeEvent) => {
				console.log('onDidChangeTextDocument', e.document.fileName)
				if (e.document.languageId === 'aml' && previewPanel) {
					updateAmlPreview(e.document, previewPanel)
				}
			}, null, context.subscriptions)
		]
		previewPanel.onDidDispose(() => {
			console.log('onDidDispose', previewPanel?.title)
			previewPanel = undefined
			subscriptions.map(s => s.dispose())
		}, null, context.subscriptions)
	}
	updateAmlPreview(editor.document, previewPanel)
}

const updateAmlPreview = debounce((document: TextDocument, panel: WebviewPanel) => updateAmlPreviewReal(document, panel), 300)
const updateAmlPreviewReal = (document: TextDocument, panel: WebviewPanel) => {
	const html = buildAmlPreview(document.getText())
	if (html) {
		panel.title = 'Preview ' + document.fileName
		panel.webview.html = html
		if (!panel.visible) {panel.reveal(ViewColumn.Beside, true)}
	}
}

function buildAmlPreview(aml: string): string | undefined {
	const res = parseAml(aml)
	if (res.result) {
		const mermaid = generateMermaid(res.result)
		// TODO: render mermaid as svg
		return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AML preview</title>
</head>
<body>
    <pre>${mermaid}</pre>
</body>
</html>`
	}
}

// utils functions

async function openFileResult(res: ParserResult<{lang: string, content: string}>): Promise<TextDocument | undefined> {
	const error = formatErrors(res.errors)
	const file = res.result
	if (file) {
		error && vscode.window.showWarningMessage(error)
		return await openFile(file.lang, file.content)
	} else {
		error && vscode.window.showErrorMessage(error)
	}
}

async function openFile(language: string, content: string): Promise<TextDocument> {
	const doc: TextDocument = await vscode.workspace.openTextDocument({language, content})
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

function debounce<F extends (...args: Parameters<F>) => ReturnType<F>>(
	func: F,
	delay: number
): (...args: Parameters<F>) => void {
	let timeout: NodeJS.Timeout
	return (...args: Parameters<F>): void => {
		clearTimeout(timeout)
		timeout = setTimeout(() => func(...args), delay)
	}
}
