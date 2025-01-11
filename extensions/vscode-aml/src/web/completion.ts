import {
    CancellationToken,
    CompletionContext,
    CompletionItem,
    CompletionItemKind,
    CompletionItemProvider,
    CompletionList,
    Position,
    ProviderResult,
    SnippetString,
    TextDocument
} from "vscode";
// @ts-ignore
import {Suggestion, SuggestionKind} from "@azimutt/aml/out/editor";
import {getDocument} from "./cache";

const amlLib = import("@azimutt/aml");

export class AmlCompletion implements CompletionItemProvider {
    provideCompletionItems(document: TextDocument, position: Position, token: CancellationToken, context: CompletionContext): ProviderResult<CompletionItem[] | CompletionList<CompletionItem>> {
        return amlLib.then(aml => getDocument(document).then(doc => {
            if (doc.schema) {
                const line = document.lineAt(position.line).text.slice(0, position.character)
                const prevLine = position.line > 0 ? document.lineAt(position.line - 1).text : ''
                return aml.ast.computeSuggestions(line, prevLine, doc.schema).map(suggestionToCompletionItem)
            }
        }))
    }

    resolveCompletionItem?(item: CompletionItem, token: CancellationToken): ProviderResult<CompletionItem> {
        throw new Error("Method not implemented.")
    }
}

function suggestionToCompletionItem(s: Suggestion): CompletionItem {
    const item = new CompletionItem(s.label || s.insert)
    item.kind = completionItem(s.kind)
    item.insertText = s.insert.includes('$') ? new SnippetString(s.insert) : s.insert
    item.documentation = s.documentation
    return item
}

function completionItem(kind: SuggestionKind) {
    if (kind === 'entity') { return CompletionItemKind.User }
    if (kind === 'attribute') { return CompletionItemKind.Class }
    if (kind === 'pk') { return CompletionItemKind.User }
    if (kind === 'index') { return CompletionItemKind.Property }
    if (kind === 'unique') { return CompletionItemKind.Issue }
    if (kind === 'check') { return CompletionItemKind.Operator }
    if (kind === 'property') { return CompletionItemKind.Property }
    if (kind === 'value') { return CompletionItemKind.Value }
    if (kind === 'relation') { return CompletionItemKind.Interface }
    if (kind === 'type') { return CompletionItemKind.TypeParameter }
    if (kind === 'default') { return CompletionItemKind.File }
    return CompletionItemKind.File
}
