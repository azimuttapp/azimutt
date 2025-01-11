import vscode, {
    DiagnosticCollection,
    Disposable,
    ExtensionContext,
    TextDocument,
    TextDocumentChangeEvent,
    TextEditor
} from "vscode";
import {newAml} from "./new";
import {convertAmlToDialect, convertJsonToAml, convertSqlToAml} from "./convert";
import {openInAzimutt} from "./open";
import {previewAml} from "./preview";
import {computeDiagnostics} from "./diagnostics";
import {AmlCompletion} from "./completion";
import {AmlRename} from "./rename";
import {AmlSymbols} from "./symbols";
import {setDocument} from "./cache";
import {debounce} from "./utils";

export function activate(context: ExtensionContext) {
    const diagnostics: DiagnosticCollection = vscode.languages.createDiagnosticCollection('aml')

    vscode.workspace.onDidOpenTextDocument((document: TextDocument) => {
        if (document.languageId === 'aml') {
            setDocument(document).then(doc => diagnostics.set(document.uri, computeDiagnostics(doc)))
        }
    }, null, context.subscriptions)
    vscode.workspace.onDidChangeTextDocument(debounce((event: TextDocumentChangeEvent) => {
        if (event.document.languageId === 'aml') {
            setDocument(event.document).then(doc => diagnostics.set(event.document.uri, computeDiagnostics(doc)))
        }
    }, 300), null, context.subscriptions)

    context.subscriptions.push(
        vscode.commands.registerCommand('aml.new', () => newAml()),
        vscode.commands.registerTextEditorCommand('aml.fromJson', (editor: TextEditor) => convertJsonToAml(editor)),
        vscode.commands.registerTextEditorCommand('aml.fromSQL', (editor: TextEditor) => convertSqlToAml(editor)),
        vscode.commands.registerTextEditorCommand('aml.convert', (editor: TextEditor) => convertAmlToDialect(editor)),
        vscode.commands.registerTextEditorCommand('aml.open', (editor: TextEditor) => openInAzimutt(editor)),
        vscode.commands.registerTextEditorCommand('aml.preview', (editor: TextEditor) => previewAml(editor, context)),
        new Disposable(() => diagnostics.dispose()),
        vscode.languages.registerCompletionItemProvider({language: 'aml'}, new AmlCompletion(), ' ', '(', '{', ',', '.'),
        vscode.languages.registerRenameProvider({language: 'aml'}, new AmlRename()),
        vscode.languages.registerDocumentSymbolProvider({language: 'aml'}, new AmlSymbols()),
    )
}

export function deactivate() {}
