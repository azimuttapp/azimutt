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
// cf https://microsoft.github.io/monaco-editor/typedoc/interfaces/languages.CodeActionProvider.html
export interface CodeActionProvider {
    provideCodeActions(model: ITextModel, range: Range, context: CodeActionContext, token: CancellationToken): ProviderResult<CodeActionList>
    resolveCodeAction?(codeAction: CodeAction, token: CancellationToken): ProviderResult<CodeAction>
}
export interface CodeActionContext {
    only?: string
    trigger: CodeActionTriggerType
    markers: IMarkerData[]
}
export enum CodeActionTriggerType {Auto = 2, Invoke = 1}
export interface CodeActionList {
    actions: readonly CodeAction[]
    dispose(): void
}
// cf https://microsoft.github.io/monaco-editor/typedoc/interfaces/languages.CodeAction.html
export interface CodeAction {
    title: string
    kind?: 'quickfix' | string
    diagnostics?: IMarkerData[]
    edit?: WorkspaceEdit
    command?: Command
    disabled?: string
    isAI?: boolean
    isPreferred?: boolean
    ranges?: IRange[]
}
export interface WorkspaceEdit {
    edits: (IWorkspaceFileEdit | IWorkspaceTextEdit)[]
}
export interface IWorkspaceFileEdit {
    metadata?: WorkspaceEditMetadata
    newResource?: Uri
    oldResource?: Uri
    options?: WorkspaceFileEditOptions
}
export interface WorkspaceEditMetadata {
    description?: string
    label: string
    needsConfirmation: boolean
}
export interface WorkspaceFileEditOptions {
    copy?: boolean
    folder?: boolean
    ignoreIfExists?: boolean
    ignoreIfNotExists?: boolean
    maxSize?: number
    overwrite?: boolean
    recursive?: boolean
    skipTrashBin?: boolean
}
export interface IWorkspaceTextEdit {
    resource: Uri
    versionId: number
    textEdit: TextEdit & { insertAsSnippet?: boolean }
    metadata?: WorkspaceEditMetadata
}
export interface TextEdit {
    eol?: EndOfLineSequence
    range: IRange
    text: string
}
export enum EndOfLineSequence {CRLF = 1, LF = 0}
export interface IMarkerData {
    message: string
    severity: MarkerSeverity
    startLineNumber: number
    startColumn: number
    endLineNumber: number
    endColumn: number
    modelVersionId?: number
    code?: string | { target: Uri; value: string }
    relatedInformation?: IRelatedInformation[]
    source?: string
    tags?: MarkerTag[]
}
export enum MarkerSeverity {Error = 8, Hint = 1, Info = 2, Warning = 4}
export enum MarkerTag {Deprecated = 2, Unnecessary = 1}
export interface IRelatedInformation {
    resource: Uri
    message: string
    startLineNumber: number
    startColumn: number
    endLineNumber: number
    endColumn: number
}
// cf https://microsoft.github.io/monaco-editor/typedoc/interfaces/languages.CodeLensProvider.html
export interface CodeLensProvider {
    onDidChange?: IEvent<CodeLensProvider>
    provideCodeLenses(model: ITextModel, token: CancellationToken): ProviderResult<CodeLensList>
    resolveCodeLens?(model: ITextModel, codeLens: CodeLens, token: CancellationToken): ProviderResult<CodeLens>
}
export interface CodeLensList {
    lenses: CodeLens[]
    dispose(): void
}
export interface CodeLens {
    command?: Command
    id?: string
    range: IRange
}
export interface Command {
    arguments?: any[]
    id: string
    title: string
    tooltip?: string
}
// cf https://microsoft.github.io/monaco-editor/typedoc/interfaces/editor.ITextModel.html
export interface ITextModel {
    id: string
    uri: Uri
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
// cf https://microsoft.github.io/monaco-editor/typedoc/interfaces/editor.IStandaloneCodeEditor.html
export interface IStandaloneCodeEditor {
    focus(): void
    getModel(): ITextModel
    getPosition(): Position
    getSelection(): Selection
    getSelections(): Selection[]
    dispose(): void
    // others...
}
export interface IRange {
    startLineNumber: number
    startColumn: number
    endLineNumber: number
    endColumn: number
}
export interface Range extends IRange {
    positionLineNumber: number
    positionColumn: number
    selectionStartLineNumber: number
    selectionStartColumn: number
    isEmpty(): boolean
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
// cf https://microsoft.github.io/monaco-editor/typedoc/classes/Selection.html
export interface Selection {
    startLineNumber: number
    startColumn: number
    endLineNumber: number
    endColumn: number
    positionLineNumber: number
    positionColumn: number
    selectionStartColumn: number
    selectionStartLineNumber: number
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
export interface Uri extends UriComponents {}
export type IEvent<T> = ((listener: (e: T) => any, thisArg?: any) => IDisposable)
export type ProviderResult<T> = T | undefined | null | Thenable<T | undefined | null>
export type Thenable<T> = PromiseLike<T>
