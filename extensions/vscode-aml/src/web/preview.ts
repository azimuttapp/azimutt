import vscode, {
    ExtensionContext,
    TextDocument,
    TextDocumentChangeEvent,
    TextEditor,
    ViewColumn,
    WebviewPanel
} from "vscode";
import {debounce} from "./utils";

let previewPanel: WebviewPanel | undefined = undefined

export function previewAml(editor: TextEditor, context: ExtensionContext) {
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
