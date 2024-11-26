import vscode, {ExtensionContext, TextEditor} from "vscode";
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
