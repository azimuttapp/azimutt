import {
    CancellationToken,
    DocumentSymbol,
    DocumentSymbolProvider,
    ProviderResult,
    SymbolInformation,
    SymbolKind,
    TextDocument
} from "vscode";
import {getDocument} from "./cache";
import {tokenToRange} from "./utils";

// see https://microsoft.github.io/monaco-editor/typedoc/interfaces/languages.DocumentSymbolProvider.html
export class AmlSymbols implements DocumentSymbolProvider {
    provideDocumentSymbols(document: TextDocument, token: CancellationToken): ProviderResult<SymbolInformation[] | DocumentSymbol[]> {
        return getDocument(document).then(doc => {
            return (doc.ast?.statements || []).flatMap(s => {
                if (s.kind === 'Entity') {
                    const entity = new DocumentSymbol(s.name.value, '', SymbolKind.Class, tokenToRange(s.meta.position), tokenToRange(s.name.token.position))
                    entity.children = s.attrs?.map(a => {
                        const name = a.path[a.path.length - 1]
                        return new DocumentSymbol(name.value, '', SymbolKind.Property, tokenToRange(a.meta.position), tokenToRange(name.token.position))
                    }) || []
                    return [entity]
                } else if (s.kind === 'Type') {
                    return [new DocumentSymbol(s.name.value, '', SymbolKind.Enum, tokenToRange(s.meta.position), tokenToRange(s.name.token.position))]
                } else {
                    return []
                }
            })
        })
    }
}
