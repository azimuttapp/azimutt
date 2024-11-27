import {isNotUndefined} from "@azimutt/utils";
import {Database, ParserError} from "@azimutt/models";
import {parseAml} from "../index";
import {computeSuggestions, Suggestion, SuggestionKind} from "../editor";
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

// TODO: use hover provider to show entity/type definition or AML doc
// TODO: enable refactorings to rename an entity/attribute (ctrl+r)

// keep Regex in sync with backend/assets/js/aml.hljs.ts
export const entityRegex = /^[a-zA-Z_][a-zA-Z0-9_#]*/
export const attributeNameRegex = /^ +[a-zA-Z_][a-zA-Z0-9_#]*/
export const attributeTypeRegex = /\b(uuid|(var|n)?char2?|character( +varying)?|(tiny|medium|long|ci)?text|(tiny|small|big)?int(eger)?(\d+)?|numeric|float|double( +precision)?|bool(ean)?|timestamp( +with(out)? +time +zone)?|date(time)?|time( +with(out)? +time +zone)?|interval|json|string|number)\b/
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
    triggerCharacters: [' ', '(', '{', ',', '.'],
    provideCompletionItems(model: ITextModel, position: Position, context: CompletionContext, token: CancellationToken): ProviderResult<CompletionList> {
        // const autoCompletion = !!context.triggerCharacter // if completion is automatically triggered or manually (cf triggerCharacters)
        const beforeCursor = model.getLineContent(position.lineNumber).slice(0, position.column - 1) // the text before the cursor
        // const after = model.getLineContent(position.lineNumber).slice(position.column - 1) // the text after the cursor
        // console.log(`provideCompletionItems(<${before}> | <${after}>)`)
        const prevLine = position.lineNumber > 1 ? model.getLineContent(position.lineNumber - 1) : ''
        let database: Database | undefined = (model as any).context?.database // parsed database can be set externally (avoid parsing twice), use let for lazy parsing only if needed
        const getDb = (): Database => {
            // lazily parse the model if needed
            database = database || parseAml(model.getValue()).result
            return database || {}
        }
        const suggestions: Suggestion[] = computeSuggestions(beforeCursor, prevLine, getDb())
        return {suggestions: suggestions.map(s => suggestionToCompletion(s, position))}
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
    const severity = e.level === 'error' ? MarkerSeverity.Error : e.level === 'warning' ? MarkerSeverity.Warning : e.level === 'info' ? MarkerSeverity.Info : MarkerSeverity.Hint
    if (e.position.start.line === 0 || e.position.start.column === 0) { // unknown position :/
        const cursor = editor.getPosition()
        return {
            message: e.message,
            severity,
            startLineNumber: cursor.lineNumber,
            startColumn: 1,
            endLineNumber: cursor.lineNumber,
            endColumn: cursor.column, // position until where to replace text, useful to replace a value on suggestion
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

function suggestionToCompletion(suggestion: Suggestion, position: Position): CompletionItem {
    return {
        label: suggestion.label || suggestion.insert,
        kind: completionItem(suggestion.kind),
        insertText: suggestion.insert,
        insertTextRules: suggestion.insert.includes('$') ? CompletionItemInsertTextRule.InsertAsSnippet : undefined,
        range: {
            startLineNumber: position.lineNumber,
            startColumn: position.column,
            endLineNumber: position.lineNumber,
            endColumn: position.column,
        },
        documentation: suggestion.documentation,
    }
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
