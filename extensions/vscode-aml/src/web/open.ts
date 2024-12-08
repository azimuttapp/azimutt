import * as vscode from "vscode";
import {TextEditor, Uri} from "vscode";

export async function openInAzimutt(editor: TextEditor): Promise<void> {
    if (editor.document.languageId !== 'aml') {
        vscode.window.showErrorMessage('Needs AML file to open in Azimutt.')
        return
    }

    const aml = editor.document.getText()
    vscode.env.openExternal(Uri.parse(openInAzimuttUrl(aml)))
}

export function openInAzimuttUrl(aml: string): string {
    return 'https://azimutt.app/create?aml=' + encodeURIComponent(aml)
}
