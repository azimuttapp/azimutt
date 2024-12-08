import * as vscode from "vscode";
import {
    ExtensionContext,
    TextDocument,
    TextDocumentChangeEvent,
    TextEditor,
    ViewColumn,
    WebviewPanel
} from "vscode";
import {Database} from "@azimutt/models";
import {generateMermaid, parseAml} from "./aml";
import {openInAzimuttUrl} from "./open";
import {debounce} from "./utils";

let previewPanel: WebviewPanel | undefined = undefined

export function previewAml(editor: TextEditor, context: ExtensionContext): void {
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
async function updateAmlPreviewReal(document: TextDocument, panel: WebviewPanel) {
    const input = document.getText()
    const res = await parseAml(input)
    if (res.result) {
        panel.title = 'Preview ' + document.fileName.split('/').pop()
        panel.webview.html = await buildAmlPreview(input, res.result)
        if (!panel.visible) {panel.reveal(ViewColumn.Beside, true)}
    }
}

async function buildAmlPreview(input: string, db: Database): Promise<string> {
    // const darkMode = vscode.window.activeColorTheme.kind === ColorThemeKind.Dark
    const mermaidCode = await generateMermaid(db)
    return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AML preview</title>
</head>
<body>
    <a href="${openInAzimuttUrl(input)}" target="_blank">Open in Azimutt</a>
    <h1>WORK IN PROGRESS</h1>
    <p>Just showing you Mermaid code, in case you want to use it on <a href="https://mermaid.live" target="_blank">mermaid.live</a>:</p>
    <pre>${mermaidCode}</pre>
</body>
</html>`
}
