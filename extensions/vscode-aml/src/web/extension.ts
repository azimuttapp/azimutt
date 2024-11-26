import vscode, {ExtensionContext, TextEditor} from "vscode";
import {newAml} from "./new";
import {convertAmlToDialect, convertJsonToAml, convertSqlToAml} from "./convert";
import {AmlDocumentSymbolProvider} from "./symbols";
import {previewAml} from "./preview";

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
