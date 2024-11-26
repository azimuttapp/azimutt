import {
    CancellationToken,
    CompletionContext,
    CompletionItem,
    CompletionItemProvider,
    CompletionList,
    Position,
    ProviderResult,
    TextDocument
} from "vscode";
const amlLib = import("@azimutt/aml");

export class AmlCompletionItemProvider implements CompletionItemProvider {
    provideCompletionItems(document: TextDocument, position: Position, token: CancellationToken, context: CompletionContext): ProviderResult<CompletionItem[] | CompletionList<CompletionItem>> {
        console.log('provideCompletionItems', position)
        return amlLib.then(aml => {
            // aml.monaco.completion().provideCompletionItems(document, position, context, token)
            // FIXME: model.getLineContent is not a function: TypeError: model.getLineContent is not a function
            // vscode & monaco are not really aligned, needs better interface
            throw new Error("Method not implemented.")
        })
    }
    resolveCompletionItem?(item: CompletionItem, token: CancellationToken): ProviderResult<CompletionItem> {
        throw new Error("Method not implemented.")
    }
}
