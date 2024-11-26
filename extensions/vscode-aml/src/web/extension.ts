import vscode, {ExtensionContext, TextEditor} from "vscode";
import {newAml} from "./new";
import {convertAmlToDialect, convertJsonToAml, convertSqlToAml} from "./convert";
import {previewAml} from "./preview";
import {startDiagnostics} from "./diagnostics";
import {AmlDocumentSymbolProvider} from "./symbols";

export function activate(context: ExtensionContext) {
    context.subscriptions.push(
        vscode.commands.registerCommand('aml.new', () => newAml()),
        vscode.commands.registerTextEditorCommand('aml.fromJson', (editor: TextEditor) => convertJsonToAml(editor)),
        vscode.commands.registerTextEditorCommand('aml.fromSQL', (editor: TextEditor) => convertSqlToAml(editor)),
        vscode.commands.registerTextEditorCommand('aml.convert', (editor: TextEditor) => convertAmlToDialect(editor)),
        vscode.commands.registerTextEditorCommand('aml.preview', (editor: TextEditor) => previewAml(editor, context)),
        startDiagnostics(context),
        // vscode.languages.registerCompletionItemProvider({language: 'aml'}, new AmlCompletionItemProvider(), ' ', '(', '{', ',', '.'),
        vscode.languages.registerDocumentSymbolProvider({language: 'aml'}, new AmlDocumentSymbolProvider()),
    )
}

export function deactivate() {}
