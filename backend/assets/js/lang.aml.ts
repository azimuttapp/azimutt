import {HLJSApi, Language} from "highlight.js"
import {
    CancellationToken,
    CompletionContext,
    CompletionItemKind,
    CompletionItemProvider,
    CompletionList,
    IMonarchLanguage,
    ITextModel,
    Position,
    ProviderResult
} from "./monaco"

const entityRegex = /^[a-zA-Z_]+/
const attributeNameRegex = /^ +[a-zA-Z_]+/
const attributeTypeRegex = /\b(uuid|varchar|text|int|boolean|timestamp)\b/
const keywordRegex = /\b(namespace|nullable|pk|index|unique|check|fk|rel|type)\b/
const notesRegex = /\|[^#\n]*/
const commentRegex = /#.*/

// see https://highlightjs.readthedocs.io/en/latest/language-guide.html
export function amlHljs(hljs: HLJSApi): Language {
    return {
        name: 'aml',
        case_insensitive: true,
        keywords: ['namespace', 'nullable', 'pk', 'index', 'unique', 'check', 'fk', 'rel', 'type'],
        contains: [
            {scope: 'title', begin: entityRegex},
            {scope: 'title.class', begin: attributeNameRegex},
            // FIXME: {scope: 'type', beginScope: 'title.class', begin: / [a-zA-Z]+/, end: / |\(|=|\n/}, // attribute type
            {scope: 'type', begin: attributeTypeRegex},
            {scope: 'subst', begin: /-> |fk /, end: /[) \n]/}, // inline relation
            {scope: 'string', begin: notesRegex},
            {scope: 'comment', begin: commentRegex},
        ]
    }
}

// see https://microsoft.github.io/monaco-editor/playground.html?source=v0.51.0#example-extending-language-services-custom-languages
// see https://microsoft.github.io/monaco-editor/monarch.html
export const amlMonarch: IMonarchLanguage = {
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
export const amlMonacoCompletion: CompletionItemProvider = {
    provideCompletionItems: (model: ITextModel, position: Position, context: CompletionContext, token: CancellationToken): ProviderResult<CompletionList> => {
        const word = model.getWordUntilPosition(position)
        const range = {
            startLineNumber: position.lineNumber,
            startColumn: position.column,
            endLineNumber: position.lineNumber,
            endColumn: position.column,
        }
        if (word.word === 'id') {
            return {suggestions: [
                {label: 'uuid pk', kind: CompletionItemKind.Property, insertText: ' uuid pk', range},
                {label: 'bigint pk', kind: CompletionItemKind.Property, insertText: ' bigint pk', range},
            ]}
        } else if (word.word === 'created_at') {
            return {suggestions: [
                {label: 'timestamp', kind: CompletionItemKind.Property, insertText: ' timestamp', range},
                {label: 'timestamp=`now()`', kind: CompletionItemKind.Property, insertText: ' timestamp=`now()`', range},
            ]}
        }
    }
}
