import {createToken, EmbeddedActionsParser, IRecognitionException, IToken, Lexer, TokenType} from "chevrotain";
import {removeUndefined} from "@azimutt/utils";
import {removeEmpty} from "./utils";

// special
const WhiteSpace = createToken({name: 'WhiteSpace', pattern: /\s+/, group: Lexer.SKIPPED})
const Identifier = createToken({ name: 'Identifier', pattern: /"([^\\"]|\\\\|\\")*"|[a-zA-Z]\w*/ })
const Note = createToken({ name: 'Note', pattern: /\|[^#\n]*/ })
// const NoteMultiline = createToken({ name: 'NoteMultiline', pattern: /\|\|\|.*\|\|\|/ })
const Comment = createToken({ name: 'Comment', pattern: /#[^\n]*/ })

// values
const Float = createToken({ name: 'Float', pattern: /\d+\.\d+/ })
const Integer = createToken({ name: 'Integer', pattern: /\d+/, longer_alt: Float })
const String = createToken({ name: 'String', pattern: /'([^\\']|\\\\|\\')*'/ })
const Boolean = createToken({ name: 'Boolean', pattern: /true|false/, longer_alt: Identifier })
const valueTokens: TokenType[] = [Integer, Float, String, Boolean]

// keywords
const Namespace = createToken({ name: 'Namespace', pattern: /namespace/, longer_alt: Identifier })
const As = createToken({ name: 'As', pattern: /as/, longer_alt: Identifier })
const Nullable = createToken({ name: 'Nullable', pattern: /nullable/, longer_alt: Identifier })
const PrimaryKey = createToken({ name: 'PrimaryKey', pattern: /pk/, longer_alt: Identifier })
const Index = createToken({ name: 'Index', pattern: /index/, longer_alt: Identifier })
const Unique = createToken({ name: 'Unique', pattern: /unique/, longer_alt: Identifier })
const Check = createToken({ name: 'Check', pattern: /check/, longer_alt: Identifier })
const Relation = createToken({ name: 'Relation', pattern: /rel/, longer_alt: Identifier })
const Type = createToken({ name: 'Type', pattern: /type/, longer_alt: Identifier })
const Enum = createToken({ name: 'Enum', pattern: /enum/, longer_alt: Identifier })
const keywordTokens: TokenType[] = [Namespace, As, Nullable, PrimaryKey, Index, Unique, Check, Relation, Type]

// chars
const Dot = createToken({ name: 'Dot', pattern: /\./ })
const Comma = createToken({ name: 'Comma', pattern: /,/ })
const Colon = createToken({ name: 'Colon', pattern: /:/ })
const Equal = createToken({ name: 'Equal', pattern: /=/ })
const Dash = createToken({ name: 'Dash', pattern: /-/ })
const GreaterThan = createToken({ name: 'GreaterThan', pattern: />/ })
const LowerThan = createToken({ name: 'LowerThan', pattern: /</ })
const LParen = createToken({ name: 'LParen', pattern: /\(/ })
const RParen = createToken({ name: 'RParen', pattern: /\)/ })
const LCurly = createToken({ name: 'LCurly', pattern: /\{/ })
const RCurly = createToken({ name: 'RCurly', pattern: /\}/ })
const charTokens: TokenType[] = [Dot, Comma, Colon, Equal, Dash, GreaterThan, LowerThan, LParen, RParen, LCurly, RCurly]

// token order is important as they are tried in order, so the Identifier must be last
const allTokens: TokenType[] = [WhiteSpace, ...charTokens, ...keywordTokens, ...valueTokens, Identifier, Note, Comment]

export type Position = [number, number]
export type TokenInfo = {token: string, offset: Position, line: Position, column: Position}
export type ParserError = {kind: string, message: string, offset: Position, line: Position, column: Position}
export type ParserResult<T> = {
    result?: T
    errors?: ParserError[]
    warnings?: ParserError[]
}

export type AmlAst = StatementAst[]
export type StatementAst = NamespaceAst | EntityAst | RelationAst | TypeAst
export type NamespaceAst = { command: 'NAMESPACE', schema: IdentifierAst, catalog?: IdentifierAst, database?: IdentifierAst }
export type EntityAst = { command: 'ENTITY', name: IdentifierAst, alias?: IdentifierAst, columns: ColumnAst[] } & NamespaceRefAst & ExtraAst
export type RelationAst = { command: 'RELATION', kind: RelationKindAst, src: ColumnRefCompositeAst, ref: ColumnRefCompositeAst, polymorphic?: RelationPolymorphicAst } & ExtraAst
export type TypeAst = { command: 'TYPE', name: IdentifierAst, content: TypeEnumAst | TypeStructAst | TypeCustomAst }

export type ColumnAst = { name: IdentifierAst, nullable?: {parser: TokenInfo} } & ColumnTypeAst & ColumnConstraintsAst & { relation?: ColumnRelationAst } & ExtraAst
export type ColumnTypeAst = { type?: IdentifierAst, enumValues?: ColumnValueAst[], defaultValue?: ColumnValueAst }
export type ColumnConstraintsAst = { primaryKey?: { parser: TokenInfo }, index?: ColumnConstraintAst, unique?: ColumnConstraintAst, check?: ColumnConstraintAst }
export type ColumnConstraintAst = { parser: TokenInfo, value?: IdentifierAst }
export type ColumnRelationAst = { kind: RelationKindAst, ref: ColumnRefCompositeAst, polymorphic?: RelationPolymorphicAst }

export type RelationCardinalityAst = '1' | 'n'
export type RelationKindAst = `${RelationCardinalityAst}-${RelationCardinalityAst}`
export type RelationPolymorphicAst = { column: ColumnPathAst, value: ColumnValueAst }

export type TypeEnumAst = { kind: 'enum', values: ColumnValueAst[] }
export type TypeStructAst = { kind: 'struct', columns: ColumnAst[] }
export type TypeCustomAst = { kind: 'custom', definition: IdentifierAst }

export type NamespaceRefAst = { schema?: IdentifierAst, catalog?: IdentifierAst, database?: IdentifierAst }
export type EntityRefAst = { entity: IdentifierAst } & NamespaceRefAst
export type ColumnPathAst = IdentifierAst & { path?: IdentifierAst[] }
export type ColumnRefAst = EntityRefAst & { column: ColumnPathAst }
export type ColumnRefCompositeAst = EntityRefAst & { columns: ColumnPathAst[] }
export type ColumnValueAst = IdentifierAst | IntegerAst

export type ExtraAst = { properties?: PropertiesAst, note?: NoteAst, comment?: CommentAst }
export type PropertiesAst = PropertyAst[]
export type PropertyAst = { key: IdentifierAst, value?: PropertyValueAst }
export type PropertyValueAst = IdentifierAst | IntegerAst
export type NoteAst = { note: string, parser: TokenInfo }
export type CommentAst = { comment: string, parser: TokenInfo }
export type IdentifierAst = { identifier: string, parser: TokenInfo }
export type IntegerAst = { value: number, parser: TokenInfo }

// TODO: indentation: https://github.com/chevrotain/chevrotain/blob/master/examples/lexer/python_indentation/python_indentation.js
// TODO: legacy rules
class AmlParser extends EmbeddedActionsParser {
    // common
    integerRule: () => IntegerAst
    identifierRule: () => IdentifierAst
    commentRule: () => CommentAst
    noteRule: () => NoteAst
    propertiesRule: () => PropertiesAst
    extraRule: () => ExtraAst
    entityRefRule: () => EntityRefAst
    columnPathRule: () => ColumnPathAst
    columnRefRule: () => ColumnRefAst
    columnRefCompositeRule: () => ColumnRefCompositeAst
    columnValueRule: () => ColumnValueAst

    // namespace
    namespaceRule: () => NamespaceAst

    // entity
    columnRule: () => ColumnAst
    entityRule: () => EntityAst

    // relation
    relationRule: () => RelationAst

    // type
    typeRule: () => TypeAst

    // general
    // amlStatementRule: () => AmlStatementAst
    // amlRule: () => AmlAst

    constructor(tokens: TokenType[]) {
        super(tokens)
        const $ = this

        // common rules
        this.integerRule = $.RULE<() => IntegerAst>('integerRule', () => {
            const token = $.CONSUME(Integer)
            return {value: parseInt(token.image), parser: parserInfo(token)}
        })

        this.identifierRule = $.RULE<() => IdentifierAst>('identifierRule', () => {
            const token = $.CONSUME(Identifier)
            if (token.image.startsWith('"')) {
                return {identifier: token.image.slice(1, -1).replaceAll(/\\"/g, '"'), parser: parserInfo(token)}
            } else {
                return {identifier: token.image, parser: parserInfo(token)}
            }
        })

        this.commentRule = $.RULE<() => CommentAst>('commentRule', () => {
            const token = $.CONSUME(Comment)
            return {comment: token.image.slice(1).trim(), parser: parserInfo(token)}
        })

        this.noteRule = $.RULE<() => NoteAst>('noteRule', () => {
            /*return $.OR([
                { ALT: () => {
                    const token = $.CONSUME(NoteMultiline)
                    return {note: token.image.slice(1).trim(), parser: parserInfo(token)}
                }},
                { ALT: () => {
                    const token = $.CONSUME(Note)
                    return {note: token.image.slice(1).trim(), parser: parserInfo(token)}
                }},
            ])*/
            const token = $.CONSUME(Note)
            return {note: token.image.slice(1).trim(), parser: parserInfo(token)}
        })

        const propertyValueRule = $.RULE<() => PropertyValueAst>('propertyValueRule', () => {
            return $.OR([
                { ALT: () => $.SUBRULE($.identifierRule) },
                { ALT: () => $.SUBRULE($.integerRule) },
            ])
        })
        const propertyRule = $.RULE<() => PropertyAst>('propertyRule', () => {
            const key = $.SUBRULE($.identifierRule)
            const value = $.OPTION(() => {
                $.CONSUME(Colon)
                return $.SUBRULE(propertyValueRule)
            })
            return {key, value}
        })
        this.propertiesRule = $.RULE<() => PropertiesAst>('propertiesRule', () => {
            const props: PropertiesAst = []
            $.CONSUME(LCurly)
            $.MANY_SEP({
                SEP: Comma,
                DEF: () => props.push($.SUBRULE(propertyRule))
            })
            $.CONSUME(RCurly)
            return props
        })

        this.extraRule = $.RULE<() => ExtraAst>('extraRule', () => {
            const properties = $.OPTION(() => $.SUBRULE($.propertiesRule))
            const note = $.OPTION2(() => $.SUBRULE2($.noteRule))
            const comment = $.OPTION3(() => $.SUBRULE3($.commentRule))
            return removeUndefined({properties, note, comment})
        })

        const nestedRule = $.RULE<() => IdentifierAst>('nestedRule', () => {
            $.CONSUME(Dot)
            return $.SUBRULE($.identifierRule)
        })

        this.entityRefRule = $.RULE<() => EntityRefAst>('entityRefRule', () => {
            const first = $.SUBRULE($.identifierRule)
            const second = $.OPTION(() => $.SUBRULE(nestedRule))
            const third = $.OPTION2(() => $.SUBRULE2(nestedRule))
            const fourth = $.OPTION3(() => $.SUBRULE3(nestedRule))
            const [entity, schema, catalog, database] = [fourth, third, second, first].filter(i => !!i)
            return removeUndefined({entity: entity || first, schema, catalog, database})
        })

        this.columnPathRule = $.RULE<() => ColumnPathAst>('columnPathRule', () => {
            const column = $.SUBRULE($.identifierRule)
            const path: IdentifierAst[] = []
            $.MANY(() => path.push($.SUBRULE(nestedRule)))
            return removeEmpty({...column, path})
        })

        this.columnRefRule = $.RULE<() => ColumnRefAst>('columnRefRule', () => {
            const entity = $.SUBRULE($.entityRefRule)
            $.CONSUME(LParen)
            const column = $.SUBRULE($.columnPathRule)
            $.CONSUME(RParen)
            return {...entity, column}
        })

        this.columnRefCompositeRule = $.RULE<() => ColumnRefCompositeAst>('columnRefCompositeRule', () => {
            const entity = $.SUBRULE($.entityRefRule)
            $.CONSUME(LParen)
            const columns: ColumnPathAst[] = []
            $.AT_LEAST_ONE_SEP({
                SEP: Comma,
                DEF: () => columns.push($.SUBRULE($.columnPathRule))
            })
            $.CONSUME(RParen)
            return {...entity, columns}
        })

        this.columnValueRule = $.RULE<() => ColumnValueAst>('columnValueRule', () => {
            return $.OR([
                { ALT: () => $.SUBRULE($.identifierRule) },
                { ALT: () => $.SUBRULE($.integerRule) },
            ])
        })

        // namespace rules
        this.namespaceRule = $.RULE<() => NamespaceAst>('namespaceRule', () => {
            $.CONSUME(Namespace)
            const first = $.SUBRULE($.identifierRule)
            const second = $.OPTION(() => $.SUBRULE(nestedRule))
            const third = $.OPTION2(() => $.SUBRULE2(nestedRule))
            const [schema, catalog, database] = [third, second, first].filter(i => !!i)
            return removeUndefined({command: 'NAMESPACE', schema: schema || first, catalog, database} as NamespaceAst)
        })

        // entity rules
        const columnTypeRule = $.RULE<() => ColumnTypeAst>('columnTypeRule', () => {
            const res = $.OPTION(() => {
                const type = $.SUBRULE($.identifierRule)
                const enumValues = $.OPTION2(() => {
                    $.CONSUME(LParen)
                    const values: ColumnValueAst[] = []
                    $.AT_LEAST_ONE_SEP({
                        SEP: Comma,
                        DEF: () => values.push($.SUBRULE($.columnValueRule))
                    })
                    $.CONSUME(RParen)
                    return values
                })
                const defaultValue = $.OPTION3(() => {
                    $.CONSUME(Equal)
                    return $.SUBRULE2($.columnValueRule)
                })
                return {type, enumValues, defaultValue}
            })
            return {type: res?.type, enumValues: res?.enumValues, defaultValue: res?.defaultValue}
        })
        const columnConstraintsRule = $.RULE<() => ColumnConstraintsAst>('columnConstraintsRule', () => {
            const pk = $.OPTION(() => $.CONSUME(PrimaryKey))
            const primaryKey = pk ? {parser: parserInfo(pk)} : undefined
            const index = $.OPTION2(() => {
                const token = $.CONSUME(Index)
                const value = $.OPTION3(() => {
                    $.CONSUME(Equal)
                    return $.SUBRULE($.identifierRule)
                })
                return removeUndefined({parser: parserInfo(token), value})
            })
            const unique = $.OPTION4(() => {
                const token = $.CONSUME(Unique)
                const value = $.OPTION5(() => {
                    $.CONSUME2(Equal)
                    return $.SUBRULE2($.identifierRule)
                })
                return removeUndefined({parser: parserInfo(token), value})
            })
            const check = $.OPTION6(() => {
                const token = $.CONSUME(Check)
                const value = $.OPTION7(() => {
                    $.CONSUME3(Equal)
                    return $.SUBRULE3($.identifierRule)
                })
                return removeUndefined({parser: parserInfo(token), value})
            })
            return removeUndefined({primaryKey, index, unique, check})
        })
        const columnRelationRule = $.RULE<() => ColumnRelationAst>('columnRelationRule', () => {
            const refCardinality = $.SUBRULE(relationCardinalityRule)
            const polymorphic = $.OPTION(() => $.SUBRULE(relationPolymorphicRule))
            const srcCardinality = $.SUBRULE2(relationCardinalityRule)
            const ref = $.SUBRULE2($.columnRefCompositeRule)
            return removeUndefined({kind: `${srcCardinality}-${refCardinality}`, ref, polymorphic} as ColumnRelationAst)
        })
        this.columnRule = $.RULE<() => ColumnAst>('columnRule', () => {
            const name = $.SUBRULE($.identifierRule)
            const {type, enumValues, defaultValue} = $.SUBRULE(columnTypeRule)
            const isNull = $.OPTION(() => $.CONSUME(Nullable))
            const nullable = isNull ? {parser: parserInfo(isNull)} : undefined
            const constraints = $.SUBRULE(columnConstraintsRule)
            const relation = $.OPTION2(() => $.SUBRULE(columnRelationRule))
            const extra = $.SUBRULE($.extraRule)
            // TODO: nested columns?
            return removeUndefined({name, type, enumValues, defaultValue, nullable, ...constraints, relation, ...extra})
        })

        this.entityRule = $.RULE<() => EntityAst>('entityRule', () => {
            const {entity, ...namespace} = $.SUBRULE($.entityRefRule)
            const alias = $.OPTION(() => {
                $.CONSUME(As)
                return $.SUBRULE($.identifierRule)
            })
            const extra = $.SUBRULE($.extraRule)
            const columns: ColumnAst[] = []
            $.MANY(() => columns.push($.SUBRULE($.columnRule)))
            return removeEmpty({command: 'ENTITY', name: entity, ...namespace, alias, ...extra, columns} as EntityAst)
        })

        // relation rules
        const relationCardinalityRule = $.RULE<() => RelationCardinalityAst>('relationCardinalityRule', () => {
            return $.OR([
                { ALT: () => { $.CONSUME(Dash); return '1' } },
                { ALT: () => { $.CONSUME(LowerThan); return 'n' } },
                { ALT: () => { $.CONSUME(GreaterThan); return 'n' } },
            ])
        })
        const relationPolymorphicRule = $.RULE<() => RelationPolymorphicAst>('relationPolymorphicRule', () => {
            const column = $.SUBRULE($.columnPathRule)
            $.CONSUME(Equal)
            const value = $.SUBRULE($.columnValueRule)
            return {column, value}
        })
        this.relationRule = $.RULE<() => RelationAst>('relationRule', () => {
            $.CONSUME(Relation)
            const src = $.SUBRULE($.columnRefCompositeRule)
            const {kind, ref, polymorphic} = $.SUBRULE(columnRelationRule)
            const extra = $.SUBRULE($.extraRule)
            return removeUndefined({command: 'RELATION', kind, src, ref, polymorphic, ...extra} as RelationAst)
        })

        // type rules
        const typeEnumRule = $.RULE<() => TypeEnumAst>('typeEnumRule', () => {
            $.CONSUME(Enum)
            $.CONSUME(LParen)
            const values: ColumnValueAst[] = []
            // TODO
            $.CONSUME(RParen)
            return { kind: 'enum', values }
        })
        const typeStructRule = $.RULE<() => TypeStructAst>('typeStructRule', () => {
            $.CONSUME(LCurly)
            const columns: ColumnAst[] = []
            // TODO
            $.CONSUME(RCurly)
            return { kind: 'struct', columns }
        })
        const typeCustomRule = $.RULE<() => TypeCustomAst>('typeCustomRule', () => {
            // TODO
            const definition = $.SUBRULE($.identifierRule)
            return { kind: 'custom', definition }
        })
        this.typeRule = $.RULE<() => TypeAst>('typeRule', () => {
            $.CONSUME(Type)
            const name = $.SUBRULE($.identifierRule)
            const content = $.OR([
                { ALT: () => $.SUBRULE(typeEnumRule) },
                { ALT: () => $.SUBRULE(typeStructRule) },
                { ALT: () => $.SUBRULE(typeCustomRule) },
            ])
            return {command: 'TYPE', name, content}
        })


        // general rules
        /*this.amlStatementRule = $.RULE<() => AmlStatementAst>('amlStatementRule', () => {
            return $.OR([
                // { ALT: () => $.SUBRULE($.entityRule) },
                // { ALT: () => $.SUBRULE($.relationRule) },
                // { ALT: () => $.SUBRULE($.typeRule) },
            ])
        })

        this.amlRule = $.RULE<() => AmlAst>('amlRule', () => {
            let stmts: AmlStatementAst[] = []
            $.MANY({
                DEF: () => stmts.push($.SUBRULE($.amlStatementRule))
            })
            return stmts
        })*/

        this.performSelfAnalysis()
    }
}

const lexer = new Lexer(allTokens)
const parser = new AmlParser(allTokens)

// exported only for tests, use the `parse` function instead
export function parseRule<T>(parse: (p: AmlParser) => T, input: string): ParserResult<T> {
    const lexingResult = lexer.tokenize(input)
    parser.input = lexingResult.tokens // "input" is a setter which will reset the parser's state.
    const res = parse(parser)
    if (parser.errors.length > 0) {
        return {errors: parser.errors.map(formatError)}
    }
    return {result: res}
}

/*export function parse(input: string): ParserResult<AmlAst> {
    return parseRule(p => p.amlRule(), input)
}*/

function formatError(err: IRecognitionException): ParserError {
    const {offset, line, column} = parserInfo(err.token)
    return {kind: err.name, message: err.message, offset, line, column}
}

function parserInfo(token: IToken): TokenInfo {
    return {
        token: token.tokenType?.name || 'missing',
        offset: [token.startOffset, token.endOffset || 0],
        line: [token.startLine || 0, token.endLine || 0],
        column: [token.startColumn || 0, token.endColumn || 0]
    }
}
