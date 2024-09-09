// types for Monaco editor used in monaco.ts

// cf https://microsoft.github.io/monaco-editor/typedoc/interfaces/languages.IMonarchLanguage.html
export interface IMonarchLanguage {
    brackets?: IMonarchLanguageBracket[]
    defaultToken?: string
    ignoreCase?: boolean
    includeLF?: boolean
    start?: string
    tokenPostfix?: string
    tokenizer: { [name: string]: IMonarchLanguageRule[] }
    unicode?: boolean
    [key: string]: any
}
// cf https://microsoft.github.io/monaco-editor/typedoc/interfaces/languages.IMonarchLanguageBracket.html
export interface IMonarchLanguageBracket {
    close: string
    open: string
    token: string
}
export type IMonarchLanguageRule = IShortMonarchLanguageRule1 | IShortMonarchLanguageRule2 | IExpandedMonarchLanguageRule
export type IShortMonarchLanguageRule1 = [string | RegExp, IMonarchLanguageAction]
export type IShortMonarchLanguageRule2 = [string | RegExp, IMonarchLanguageAction, string]
export interface IExpandedMonarchLanguageRule {
    action?: IMonarchLanguageAction
    include?: string
    regex?: string | RegExp
}
export type IMonarchLanguageAction = IShortMonarchLanguageAction | IExpandedMonarchLanguageAction | (IShortMonarchLanguageAction | IExpandedMonarchLanguageAction)[]
export type IShortMonarchLanguageAction = string
// cf https://microsoft.github.io/monaco-editor/typedoc/interfaces/languages.IExpandedMonarchLanguageAction.html
export interface IExpandedMonarchLanguageAction {
    bracket?: string
    cases?: Object
    goBack?: number
    group?: IMonarchLanguageAction[]
    log?: string
    next?: string
    nextEmbedded?: string
    switchTo?: string
    token?: string
}

// cf https://microsoft.github.io/monaco-editor/typedoc/interfaces/languages.CompletionItemProvider.html
export interface CompletionItemProvider {
    triggerCharacters?: string[]
    provideCompletionItems(model: ITextModel, position: Position, context: CompletionContext, token: CancellationToken): ProviderResult<CompletionList>
    resolveCompletionItem?(item: CompletionItem, token: CancellationToken): ProviderResult<CompletionItem>
}
// cf https://microsoft.github.io/monaco-editor/typedoc/interfaces/languages.CompletionList.html
export interface CompletionList {
    incomplete?: boolean
    suggestions: CompletionItem[]
    dispose?(): void
}
// cf https://microsoft.github.io/monaco-editor/typedoc/interfaces/languages.CompletionItem.html
export interface CompletionItem {
    additionalTextEdits?: ISingleEditOperation[]
    command?: Command
    commitCharacters?: string[]
    detail?: string
    documentation?: string | IMarkdownString
    filterText?: string
    insertText: string
    insertTextRules?: CompletionItemInsertTextRule
    kind: CompletionItemKind
    label: string | CompletionItemLabel
    preselect?: boolean
    range: IRange | CompletionItemRanges
    sortText?: string
    tags?: readonly CompletionItemTag.Deprecated[]
}
export interface CompletionItemLabel {
    description?: string
    detail?: string
    label: string
}
export interface CompletionItemRanges {
    insert: IRange
    replace: IRange
}
export enum CompletionItemInsertTextRule {InsertAsSnippet = 4, KeepWhitespace = 1, None = 0}
export enum CompletionItemKind {Class = 5, Color = 19, Constant = 14, Constructor = 2, Customcolor = 22, Enum = 15, EnumMember = 16, Event = 10, Field = 3, File = 20, Folder = 23, Function = 1, Interface = 7, Issue = 26, Keyword = 17, Method = 0, Module = 8, Operator = 11, Property = 9, Reference = 21, Snippet = 27, Struct = 6, Text = 18, TypeParameter = 24, Unit = 12, User = 25, Value = 13, Variable = 4}
export enum CompletionItemTag {Deprecated = 1}
export interface ISingleEditOperation {
    forceMoveMarkers?: boolean
    range: IRange
    text: string
}
export interface Command {
    arguments?: any[]
    id: string
    title: string
    tooltip?: string
}
export interface IMarkdownString {
    baseUri?: UriComponents
    isTrusted?: boolean | MarkdownStringTrustedOptions
    supportHtml?: boolean
    supportThemeIcons?: boolean
    uris?: { [href: string]: UriComponents }
    value: string
}
export interface MarkdownStringTrustedOptions {
    enabledCommands: readonly string[]
}
export interface IRange {
    startLineNumber: number
    startColumn: number
    endLineNumber: number
    endColumn: number
}
// cf https://microsoft.github.io/monaco-editor/typedoc/interfaces/editor.ITextModel.html
export interface ITextModel {
    id: string
    createSnapshot(preserveBOM?: boolean): ITextSnapshot // get the text stored
    getLineContent(lineNumber: number): string
    getLineCount(): number
    getOffsetAt(position: Position): number
    getPositionAt(offset: number): Position
    getValue(eol?: EndOfLinePreference, preserveBOM?: boolean): string // get the text stored
    getValueInRange(range: IRange, eol?: EndOfLinePreference): string
    getValueLength(eol?: EndOfLinePreference, preserveBOM?: boolean): number
    getValueLengthInRange(range: IRange, eol?: EndOfLinePreference): number
    getVersionId(): number // get the current version id of the model. Anytime a change happens to the model (even undo/redo), the version id is incremented.
    getWordAtPosition(position: IPosition): IWordAtPosition
    getWordUntilPosition(position: IPosition): IWordAtPosition
    modifyPosition(position: IPosition, offset: number): Position
    // others...
}
export interface ITextSnapshot { read(): string }
export enum EndOfLinePreference {CRLF = 2, LF = 1, TextDefined = 0}
export interface IWordAtPosition {
    endColumn: number
    startColumn: number
    word: string
}
export interface IPosition {
    column: number
    lineNumber: number
}
// cf https://microsoft.github.io/monaco-editor/typedoc/classes/Position.html
export interface Position {
    column: number
    lineNumber: number
}
export interface CompletionContext {
    triggerCharacter?: string
    triggerKind: CompletionTriggerKind
}
export enum CompletionTriggerKind {Invoke = 0, TriggerCharacter = 1, TriggerForIncompleteCompletions = 2}
export interface CancellationToken {
    isCancellationRequested: boolean
    onCancellationRequested: ((listener: ((e: any) => any), thisArgs?: any, disposables?: IDisposable[]) => IDisposable)
}
export interface IDisposable {
    dispose(): void
}
export interface UriComponents {
    authority?: string
    fragment?: string
    path?: string
    query?: string
    scheme: string
}
export type ProviderResult<T> = T | undefined | null | Thenable<T | undefined | null>
export type Thenable<T> = PromiseLike<T>
