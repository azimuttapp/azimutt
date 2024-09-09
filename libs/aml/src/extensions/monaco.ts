import {genAttributeRef, parseAml} from "../aml";
import {
    CancellationToken,
    CompletionContext,
    CompletionItem,
    CompletionItemInsertTextRule,
    CompletionItemKind,
    CompletionItemProvider,
    CompletionList,
    IMonarchLanguage,
    ITextModel,
    Position,
    ProviderResult
} from "./monaco.types";
import {entityToRef} from "@azimutt/models";

// keep Regex in sync with backend/assets/js/lang.aml.ts
export const entityRegex = /^[a-zA-Z_][a-zA-Z0-9_#]*/
export const attributeNameRegex = /^ +[a-zA-Z_][a-zA-Z0-9_#]*/
export const attributeTypeRegex = /\b(uuid|varchar|text|int|boolean|timestamp)\b/
export const keywordRegex = /\b(namespace|nullable|pk|index|unique|check|fk|rel|type)\b/
export const notesRegex = /\|[^#\n]*/
export const commentRegex = /#.*/

// see https://microsoft.github.io/monaco-editor/playground.html?source=v0.51.0#example-extending-language-services-custom-languages
// see https://microsoft.github.io/monaco-editor/monarch.html
export const language: IMonarchLanguage = {
    ignoreCase: true,
    // defaultToken: 'invalid', // comment this when not working on language
    tokenizer: {
        root: [
            [entityRegex, 'entity'],
            [attributeNameRegex, 'attribute'],
            [attributeTypeRegex, 'type'],
            [keywordRegex, 'keyword'],
            [/(->|fk) [^ ]+/, 'operators'],
            [notesRegex, 'comment.doc'],
            [commentRegex, 'comment'],
        ],
    }
}
// see https://microsoft.github.io/monaco-editor/typedoc/interfaces/languages.CompletionItemProvider.html
export const completion: CompletionItemProvider = {
    triggerCharacters: [' '],
    provideCompletionItems(model: ITextModel, position: Position, context: CompletionContext, token: CancellationToken): ProviderResult<CompletionList> {
        // const autoCompletion = !!context.triggerCharacter // if completion is automatically triggered or manually (cf triggerCharacters)
        const line = model.getLineContent(position.lineNumber)
        const space = line.endsWith(' ') ? '' : ' '
        const suggestions: CompletionItem[] = []
        if (line.match(/^[a-zA-Z_][a-zA-Z0-9_#]* *$/)) { // wrote entity name
            suggestions.push(suggestSnippet('| ...', space + '| ${1:your doc}', CompletionItemKind.File, position, {documentation: 'add documentation'}))
            suggestions.push(suggestSnippet('# ...', space + '# ${1:your doc}', CompletionItemKind.File, position, {documentation: 'add comment'}))
        } else if (line.match(/^ +[a-zA-Z_][a-zA-Z0-9_#]* *$/)) { // wrote attribute name
            const attributeName = line.trim()
            if (attributeName === 'id' || attributeName.endsWith('_id') || attributeName.endsWith('Id')) {
                suggestions.push(suggestText(space + 'uuid pk', CompletionItemKind.User, position))
                suggestions.push(suggestText(space + 'bigint pk', CompletionItemKind.User, position))
            }
            if (attributeName.endsWith('_at') || attributeName.endsWith('At')) {
                suggestions.push(suggestText(space + 'timestamp', CompletionItemKind.TypeParameter, position))
                suggestions.push(suggestText(space + 'timestamp=`now()`', CompletionItemKind.TypeParameter, position))
            }
            suggestions.push(suggestText(space + 'varchar', CompletionItemKind.TypeParameter, position))
            suggestions.push(suggestText(space + 'text', CompletionItemKind.TypeParameter, position))
            suggestions.push(suggestText(space + 'integer', CompletionItemKind.TypeParameter, position))
            suggestions.push(suggestText(space + 'bigint', CompletionItemKind.TypeParameter, position))
            suggestions.push(suggestText(space + 'boolean', CompletionItemKind.TypeParameter, position))
            suggestions.push(suggestText(space + 'uuid', CompletionItemKind.TypeParameter, position))
            suggestions.push(suggestText(space + '"timestamp with time zone"', CompletionItemKind.TypeParameter, position))
        } else if (line.match(/^ +[a-zA-Z_][a-zA-Z0-9_#]* +[a-zA-Z_][a-zA-Z0-9_#]* *$/)) { // wrote attribute type
            suggestions.push(suggestText(space + 'pk', CompletionItemKind.User, position))
            suggestions.push(suggestText(space + 'unique', CompletionItemKind.Issue, position))
            suggestions.push(suggestText(space + 'index', CompletionItemKind.Property, position))
            suggestions.push(suggestText(space + 'check', CompletionItemKind.Operator, position))
            suggestions.push(suggestSnippet('| ...', space + '| ${1:your doc}', CompletionItemKind.File, position, {documentation: 'add documentation'}))
            suggestions.push(suggestSnippet('# ...', space + '# ${1:your doc}', CompletionItemKind.File, position, {documentation: 'add comment'}))
        } else if (line.match(/[-<>]{2} ?$/)) { // wrote relation
            const {result: db} = parseAml(model.getValue())
            const refs = db?.entities?.map(e => e.pk ? genAttributeRef(entityToRef(e), e.pk.attrs) : '') || []
            refs.forEach(ref => suggestions.push(suggestText(space + ref, CompletionItemKind.Interface, position)))
        }
        return {suggestions}
    },
    /*resolveCompletionItem(item: CompletionItem, token: CancellationToken): ProviderResult<CompletionItem> {
        console.log('resolveCompletionItem', item)
        return undefined
    }*/
}

function suggestText(text: string, kind: CompletionItemKind, position: Position, opts: {documentation?: string} = {}): CompletionItem {
    return {
        label: text.trim(),
        kind,
        insertText: text,
        range: {
            startLineNumber: position.lineNumber,
            startColumn: position.column,
            endLineNumber: position.lineNumber,
            endColumn: position.column + text.length,
        },
        ...opts
    }
}

function suggestSnippet(label: string, completion: string, kind: CompletionItemKind, position: Position, opts: {documentation?: string} = {}): CompletionItem {
    return {
        label,
        kind,
        insertText: completion,
        insertTextRules: CompletionItemInsertTextRule.InsertAsSnippet,
        range: {
            startLineNumber: position.lineNumber,
            startColumn: position.column,
            endLineNumber: position.lineNumber,
            endColumn: position.column + completion.length,
        },
        ...opts
    }
}
