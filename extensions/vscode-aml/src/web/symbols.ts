import {
    CancellationToken,
    DocumentSymbol,
    DocumentSymbolProvider,
    ProviderResult,
    Range,
    SymbolInformation,
    SymbolKind,
    TextDocument
} from "vscode";

// see https://microsoft.github.io/monaco-editor/typedoc/interfaces/languages.DocumentSymbolProvider.html
export class AmlDocumentSymbolProvider implements DocumentSymbolProvider {
    provideDocumentSymbols(document: TextDocument, token: CancellationToken): ProviderResult<SymbolInformation[] | DocumentSymbol[]> {
        const symbols: DocumentSymbol[] = []
        const regex = /(^|\n)(type\s+)?((?:[a-zA-Z_][a-zA-Z0-9_]*\.)?[a-zA-Z_][a-zA-Z0-9_]*)/g // TODO: use `.split('\n')` for "better" parsing
        let match: RegExpExecArray | null = null
        while (match = regex.exec(document.getText())) {
            const [all = '', lr = '', keyword = '', name = ''] = match || []
            if (name === 'rel') { continue }
            const range = new Range(
                document.positionAt(match.index + lr.length + keyword.length),
                document.positionAt(match.index + all.length)
            )
            // see https://microsoft.github.io/monaco-editor/typedoc/interfaces/languages.DocumentSymbol.html
            symbols.push(new DocumentSymbol(
                name,
                ``, // TODO: set entity doc if available
                keyword?.trim() === 'type' ? SymbolKind.Enum : SymbolKind.Class,
                range,
                range
            ))
        }
        return symbols
    }
}
