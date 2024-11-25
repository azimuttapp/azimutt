import vscode, {
	CancellationToken,
	DocumentSymbol,
	DocumentSymbolProvider,
	ExtensionContext,
	ProviderResult,
	Range,
	SymbolInformation,
	SymbolKind,
	TextDocument,
	TextDocumentChangeEvent,
	TextEditor,
	ViewColumn,
	WebviewPanel
} from "vscode";
// import {ParserError, ParserErrorLevel} from "@azimutt/models";
/*import {generateSql, parseSql} from "@azimutt/parser-sql";
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
} from "@azimutt/aml";*/

let previewPanel: WebviewPanel | undefined = undefined

export function activate(context: ExtensionContext) {
	context.subscriptions.push(
		vscode.commands.registerCommand('aml.new', () => newAml()),
		vscode.commands.registerTextEditorCommand('aml.fromJson', (editor: TextEditor) => convertJsonToAml(editor)),
		vscode.commands.registerTextEditorCommand('aml.fromSQL', (editor: TextEditor) => convertSqlToAml(editor)),
		vscode.commands.registerTextEditorCommand('aml.convert', (editor: TextEditor) => convertAmlToDialect(editor)),
		vscode.commands.registerTextEditorCommand('aml.preview', (editor: TextEditor) => previewAml(editor, context)),
		vscode.languages.registerDocumentSymbolProvider({language: 'aml'}, new AmlDocumentSymbolProvider()),
	)
}

export function deactivate() {}

// private functions

async function newAml() {
	await openFile('aml', `#
# Sample AML
# learn more at https://azimutt.app/aml
#

users
  id uuid pk
  name varchar index
  email varchar unique
  role user_role(admin, guest)=guest

posts | store all posts
  id uuid pk
  title varchar
  content text | allow markdown formatting
  author uuid -> users(id) # inline relation
  created_at timestamp=\`now()\`
`)
}

async function convertJsonToAml(editor: TextEditor): Promise<void> {
	if (editor.document.languageId !== 'json') {
		vscode.window.showErrorMessage('Needs JSON file to convert it to AML.')
		return
	}

	vscode.window.showInformationMessage('JSON to AML conversion not implemented yet, work in progress...')
	// FIXME: await openFileResult(parseJsonDatabase(editor.document.getText()).map((db: Database) => ({lang: 'aml', content: generateAml(db)})))
}

async function convertSqlToAml(editor: TextEditor): Promise<void> {
	if (editor.document.languageId !== 'sql') {
		vscode.window.showErrorMessage('Needs SQL file to convert it to AML.')
		return
	}

	const dialects = ['PostgreSQL']
	const dialect = await vscode.window.showQuickPick(dialects, {placeHolder: 'Select target'})
	if (dialect === 'PostgreSQL') {
		vscode.window.showInformationMessage('SQL to AML conversion not implemented yet, work in progress...')
		// FIXME: await openFileResult(parseSql(editor.document.getText(), 'postgres').map((db: Database) => ({lang: 'aml', content: generateAml(db)})))
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
	vscode.window.showInformationMessage(`AML to ${dialect} conversion not implemented yet, work in progress...`)
	/* FIXME: const res = parseAml(editor.document.getText())
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
	}*/
}

function previewAml(editor: TextEditor, context: ExtensionContext) {
	if (editor.document.languageId !== 'aml') {
		vscode.window.showErrorMessage('Needs AML file to preview it.')
		return
	}
	if (!previewPanel) {
		previewPanel = vscode.window.createWebviewPanel('aml-preview', 'Preview AML', {viewColumn: ViewColumn.Beside, preserveFocus: true}, {localResourceRoots: []})
		const subscriptions = [
			vscode.workspace.onDidOpenTextDocument((document: TextDocument) => {
				if (document.languageId === 'aml' && previewPanel) {
					updateAmlPreview(document, previewPanel)
				}
			}, null, context.subscriptions),
			vscode.workspace.onDidChangeTextDocument((event: TextDocumentChangeEvent) => {
				if (event.document.languageId === 'aml' && previewPanel) {
					updateAmlPreview(event.document, previewPanel)
				}
			}, null, context.subscriptions),
			vscode.window.onDidChangeActiveTextEditor((editor: TextEditor | undefined) => {
				if (editor && editor.document.languageId === 'aml' && previewPanel) {
					updateAmlPreview(editor.document, previewPanel)
				}
			}, null, context.subscriptions)
		]
		previewPanel.onDidDispose(() => {
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
		panel.title = 'Preview ' + document.fileName.split('/').pop()
		panel.webview.html = html
		if (!panel.visible) {panel.reveal(ViewColumn.Beside, true)}
	}
}

function buildAmlPreview(aml: string): string | undefined {
	// const res = parseAml(aml)
	// const content = res.result ? generateMermaid(res.result) : aml // TODO: render mermaid as svg
	const content = aml.trim()
	return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AML preview</title>
</head>
<body>
	<a href="${openInAzimuttUrl(aml)}" target="_blank">Open in Azimutt</a>
    <pre>${content}</pre>
</body>
</html>`
}

function openInAzimuttUrl(aml: string): string {
	return 'https://azimutt.app/create?aml=' + encodeURIComponent(aml)
}

// see https://microsoft.github.io/monaco-editor/typedoc/interfaces/languages.DocumentSymbolProvider.html
class AmlDocumentSymbolProvider implements DocumentSymbolProvider {
	provideDocumentSymbols(document: TextDocument, token: CancellationToken): ProviderResult<SymbolInformation[] | DocumentSymbol[]> {
		const symbols: DocumentSymbol[] = []
		const regex = /(^|\n)(type\s+)?((?:[a-zA-Z_][a-zA-Z0-9_]*\.)?[a-zA-Z_][a-zA-Z0-9_]*)/g
		let match: RegExpExecArray | null = null
		while (match = regex.exec(document.getText())) {
			const [all, lr, keyword, name] = match || []
			if (name === 'rel') { continue }
			const range = new Range(
				document.positionAt(match.index + lr.length + (keyword || '').length),
				document.positionAt(match.index + all.length)
			)
			// see https://microsoft.github.io/monaco-editor/typedoc/interfaces/languages.DocumentSymbol.html
			symbols.push(new DocumentSymbol(
				name,
				``, // TODO: set entity doc if available
				keyword?.trim() === 'type' ? SymbolKind.Enum : SymbolKind.Class,
				range,
				range
			))
		}
		return symbols
	}
}

// util functions

/*async function openFileResult(res: ParserResult<{lang: string, content: string}>): Promise<TextDocument | undefined> {
	const error = formatErrors(res.errors)
	const file = res.result
	if (file) {
		error && vscode.window.showWarningMessage(error)
		return await openFile(file.lang, file.content)
	} else {
		error && vscode.window.showErrorMessage(error)
	}
}*/

async function openFile(language: string, content: string): Promise<TextDocument> {
	const doc: TextDocument = await vscode.workspace.openTextDocument({language, content})
	await vscode.window.showTextDocument(doc)
	return doc
}

/*function formatErrors(errors: ParserError[] | undefined): string | undefined {
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
}*/

type Timeout = ReturnType<typeof setTimeout>
function debounce<F extends (...args: Parameters<F>) => ReturnType<F>>(
	func: F,
	delay: number
): (...args: Parameters<F>) => void {
	let timeout: Timeout
	return (...args: Parameters<F>): void => {
		clearTimeout(timeout)
		timeout = setTimeout(() => func(...args), delay)
	}
}
