import vscode, {
    Diagnostic,
    DiagnosticCollection,
    DiagnosticSeverity,
    Disposable,
    ExtensionContext,
    TextDocument,
    TextDocumentChangeEvent
} from "vscode";
import {ParserErrorLevel} from "@azimutt/models";
import {isNever} from "@azimutt/utils";
import {parseAml} from "./aml";
import {amlPositionToVSRange, debounce} from "./utils";

export function startDiagnostics(context: ExtensionContext): Disposable {
    const diagnostics: DiagnosticCollection = vscode.languages.createDiagnosticCollection('aml')
    vscode.workspace.onDidOpenTextDocument((document: TextDocument) => {
        if (document.languageId === 'aml') {
            analyzeDocument(document, diagnostics)
        }
    }, null, context.subscriptions)
    vscode.workspace.onDidChangeTextDocument((event: TextDocumentChangeEvent) => {
        if (event.document.languageId === 'aml') {
            analyzeDocument(event.document, diagnostics)
        }
    }, null, context.subscriptions)
    return new Disposable(() => diagnostics.dispose())
}

const analyzeDocument = debounce((document: TextDocument, diagnostics: DiagnosticCollection) => analyzeDocumentReal(document, diagnostics), 300)
async function analyzeDocumentReal(document: TextDocument, diagnostics: DiagnosticCollection) {
    const input = document.getText()
    const res = await parseAml(input)
    const errors: Diagnostic[] = (res.errors || []).map(e => new Diagnostic(amlPositionToVSRange(e.position), e.message, levelToSeverity(e.level)))
    diagnostics.set(document.uri, errors)
}

function levelToSeverity(level: ParserErrorLevel): DiagnosticSeverity {
    if (level === 'error') return DiagnosticSeverity.Error
    if (level === 'warning') return DiagnosticSeverity.Warning
    if (level === 'info') return DiagnosticSeverity.Information
    if (level === 'hint') return DiagnosticSeverity.Hint
    return isNever(level)
}
