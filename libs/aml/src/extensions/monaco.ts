import {isNotUndefined} from "@azimutt/utils";
import {entityToRef, ParserError} from "@azimutt/models";
import {genAttributeRef, parseAml} from "../aml";
import {
    CancellationToken,
    CodeAction,
    CodeActionContext,
    CodeActionList,
    CodeActionProvider,
    CodeActionTriggerType,
    CodeLens,
    CodeLensList,
    CodeLensProvider,
    CompletionContext,
    CompletionItem,
    CompletionItemInsertTextRule,
    CompletionItemKind,
    CompletionItemProvider,
    CompletionList,
    IMarkerData,
    IMonarchLanguage,
    IStandaloneCodeEditor,
    ITextModel,
    MarkerSeverity,
    Position,
    ProviderResult,
    Range
} from "./monaco.types";

// keep Regex in sync with backend/assets/js/lang.aml.ts
export const entityRegex = /^[a-zA-Z_][a-zA-Z0-9_#]*/
export const attributeNameRegex = /^ +[a-zA-Z_][a-zA-Z0-9_#]*/
export const attributeTypeRegex = /\b(uuid|varchar|text|int|boolean|timestamp)\b/
export const keywordRegex = /\b(namespace|nullable|pk|index|unique|check|fk|rel|type)\b/
export const notesRegex = /\|[^#\n]*/
export const commentRegex = /#.*/

// other lang inspiration: https://github.com/microsoft/monaco-editor/tree/main/src

// see https://microsoft.github.io/monaco-editor/monarch.html
// see https://microsoft.github.io/monaco-editor/playground.html?source=v0.51.0#example-extending-language-services-custom-languages
export const language = (opts: {} = {}): IMonarchLanguage => ({ // syntax highlighting
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
})

// see https://microsoft.github.io/monaco-editor/playground.html?source=v0.51.0#example-extending-language-services-custom-languages
// export const theme = (opts: {} = {}): ({})

// see https://microsoft.github.io/monaco-editor/playground.html?source=v0.51.0#example-extending-language-services-completion-provider-example
export const completion = (opts: {} = {}): CompletionItemProvider => ({ // auto-complete
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
            const refs = db?.entities?.map(e => e.pk ? genAttributeRef(entityToRef(e), e.pk.attrs, false) : '') || []
            refs.forEach(ref => suggestions.push(suggestText(space + ref, CompletionItemKind.Interface, position)))
        }
        return {suggestions}
    },
    /*resolveCompletionItem(item: CompletionItem, token: CancellationToken): ProviderResult<CompletionItem> {
        console.log('resolveCompletionItem', item)
        return undefined
    }*/
})

export const codeAction = (opts: {} = {}): CodeActionProvider => ({ // quick-fixes
    provideCodeActions(model: ITextModel, range: Range, context: CodeActionContext, token: CancellationToken): ProviderResult<CodeActionList> {
        if (context.trigger === CodeActionTriggerType.Invoke && context.only === 'quickfix') { // hover a marker
            const actions: CodeAction[] = context.markers.map(m => {
                const [, prev, next] = m.message.match(/"([^"]{1,100})".{1,100}legacy.{1,100}"([^"]{1,100})"/) || []
                if (next) {
                    return {
                        title: `Replace by '${next}'`,
                        diagnostics: [m],
                        kind: 'quickfix',
                        edit: {edits: [{
                            resource: model.uri,
                            versionId: model.getVersionId(),
                            textEdit: {text: next, range}
                        }]}
                    }
                }
            }).filter(isNotUndefined)
            return {actions, dispose() {}}
        }
        /*if (context.trigger === CodeActionTriggerType.Auto && context.only === undefined) { // change cursor position
            const actions: CodeAction[] = []
            return {actions, dispose() {}}
        }*/
    }
})

// see https://microsoft.github.io/monaco-editor/playground.html?source=v0.51.0#example-extending-language-services-codelens-provider-example
// ex: https://code.visualstudio.com/docs/editor/editingevolved#_reference-information
export const codeLens = (opts: {} = {}): CodeLensProvider => ({ // hints with actions
    provideCodeLenses(model: ITextModel, token: CancellationToken): ProviderResult<CodeLensList> {
        // console.log('provideCodeLenses')
        const lenses: CodeLens[] = []
        return {lenses, dispose() {}}
    }
})

export const createMarker = (e: ParserError, model: ITextModel, editor: IStandaloneCodeEditor): IMarkerData => {
    const severity = e.kind === 'error' ? MarkerSeverity.Error : e.kind === 'warning' ? MarkerSeverity.Warning : e.kind === 'info' ? MarkerSeverity.Info : MarkerSeverity.Hint
    if (e.position.start.line === 0 || e.position.start.column === 0) { // unknown position :/
        const cursor = editor.getPosition()
        return {
            message: e.message,
            severity,
            startLineNumber: cursor.lineNumber,
            startColumn: 1,
            endLineNumber: cursor.lineNumber,
            endColumn: cursor.column,
        }
    } else {
        return {
            message: e.message,
            severity,
            startLineNumber: e.position.start.line,
            startColumn: e.position.start.column,
            endLineNumber: e.position.end.line,
            endColumn: e.position.end.column + 1,
        }
    }
}

// entity/attribute rename: ??? (https://code.visualstudio.com/docs/editor/editingevolved#_rename-symbol)
// go to definition: `{codeEditorService: {openCodeEditor: () => {}}}` as 3rd attr of `monaco.editor.create` (https://code.visualstudio.com/docs/editor/editingevolved#_go-to-definition & https://code.visualstudio.com/docs/editor/editingevolved#_peek)
// JSON defaults (json-schema validation for json editor: JSON to AML, help with Database json-schema): https://microsoft.github.io/monaco-editor/playground.html?source=v0.51.0#example-extending-language-services-configure-json-defaults
// folding provider (like markdown, fold between top level comments): https://microsoft.github.io/monaco-editor/playground.html?source=v0.51.0#example-extending-language-services-folding-provider-example
// hover provider (show definitions of entities/attrs in relations, show incoming relations in entities/attrs definitions): https://microsoft.github.io/monaco-editor/playground.html?source=v0.51.0#example-extending-language-services-hover-provider-example

// private helpers

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
