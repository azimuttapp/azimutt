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

const amlLib = import("@azimutt/aml");

export class AmlCompletionItemProvider implements CompletionItemProvider {
    provideCompletionItems(document: TextDocument, position: Position, token: CancellationToken, context: CompletionContext): ProviderResult<CompletionItem[] | CompletionList<CompletionItem>> {
        return amlLib.then(aml => {
            const res = aml.parseAml(document.getText())
            if (res.result) {
                const beforeCursor = document.lineAt(position.line).text.slice(0, position.character)
                const prevLine = position.line > 0 ? document.lineAt(position.line - 1).text : ''
                const suggestions = aml.ast.computeSuggestions(beforeCursor, prevLine, res.result)
                return suggestions.map(suggestionToCompletionItem)
            }
        })
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
    if (kind === 'entity') return CompletionItemKind.User
    if (kind === 'attribute') return CompletionItemKind.Class
    if (kind === 'pk') return CompletionItemKind.User
    if (kind === 'index') return CompletionItemKind.Property
    if (kind === 'unique') return CompletionItemKind.Issue
    if (kind === 'check') return CompletionItemKind.Operator
    if (kind === 'property') return CompletionItemKind.Property
    if (kind === 'value') return CompletionItemKind.Value
    if (kind === 'relation') return CompletionItemKind.Interface
    if (kind === 'type') return CompletionItemKind.TypeParameter
    if (kind === 'default') return CompletionItemKind.File
    return CompletionItemKind.File
}
