import {
    createToken,
    EmbeddedActionsParser,
    ILexingError,
    IRecognitionException,
    IToken,
    Lexer,
    TokenType
} from "chevrotain";
import {isNotUndefined, removeEmpty, removeUndefined, stripIndent} from "@azimutt/utils";
import {
    mergePositions,
    ParserError,
    ParserErrorLevel,
    ParserResult,
    positionStartAdd,
    RelationCardinality,
    removeQuotes,
    TokenPosition
} from "@azimutt/models";
import {
    AmlAst,
    AttributeAstFlat,
    AttributeAstNested,
    AttributeCheckAst,
    AttributeConstraintAst,
    AttributeConstraintsAst,
    AttributePathAst,
    AttributeRefAst,
    AttributeRefCompositeAst,
    AttributeRelationAst,
    AttributeTypeAst,
    AttributeValueAst,
    BooleanToken,
    CommentToken,
    DecimalToken,
    DocToken,
    EmptyStatement,
    EntityRefAst,
    EntityStatement,
    ExpressionToken,
    ExtraAst,
    IdentifierToken,
    IntegerToken,
    NamespaceRefAst,
    NamespaceStatement,
    NullToken,
    PropertiesAst,
    PropertyAst,
    PropertyValueAst,
    RelationPolymorphicAst,
    RelationStatement,
    StatementAst,
    TokenInfo,
    TokenIssue,
    TypeAliasAst,
    TypeCustomAst,
    TypeEnumAst,
    TypeStatement,
    TypeStructAst
} from "./amlAst";
import {badIndent, legacy} from "./errors";

// special
const Comment = createToken({ name: 'Comment', pattern: /#[^\n]*/ })
const Doc = createToken({ name: 'Doc', pattern: /\|(\s+"([^\\"]|\\\\|\\")*"|([^ ]#|[^#\n])*)/ }) // # is included in doc if not preceded by a space
const DocMultiline = createToken({ name: 'DocMultiline', pattern: /\|\|\|[^]*?\|\|\|/, line_breaks: true })
const Expression = createToken({ name: 'Expression', pattern: /`[^`]+`/ })
const Identifier = createToken({ name: 'Identifier', pattern: /\b[a-zA-Z_][a-zA-Z0-9_#]*\b|"([^\\"]|\\\\|\\"|\\n)*"/ })
const NewLine = createToken({ name: 'NewLine', pattern: /\r?\n/ })
const WhiteSpace = createToken({name: 'WhiteSpace', pattern: /[ \t]+/})

// values
const Decimal = createToken({ name: 'Decimal', pattern: /\d+\.\d+/ })
const Integer = createToken({ name: 'Integer', pattern: /\d+/, longer_alt: Decimal })
const String = createToken({ name: 'String', pattern: /'([^\\']|\\\\|\\')*'/ })
const valueTokens: TokenType[] = [Integer, Decimal, String]

// keywords
const As = createToken({ name: 'As', pattern: /\bas\b/i, longer_alt: Identifier })
const Check = createToken({ name: 'Check', pattern: /\bcheck\b/i, longer_alt: Identifier })
const False = createToken({ name: 'False', pattern: /\bfalse\b/i, longer_alt: Identifier })
const Index = createToken({ name: 'Index', pattern: /\bindex\b/i, longer_alt: Identifier })
const Namespace = createToken({ name: 'Namespace', pattern: /\bnamespace\b/i, longer_alt: Identifier })
const Null = createToken({ name: 'Null', pattern: /\bnull\b/i, longer_alt: Identifier })
const Nullable = createToken({ name: 'Nullable', pattern: /\bnullable\b/i, longer_alt: Identifier })
const PrimaryKey = createToken({ name: 'PrimaryKey', pattern: /\bpk\b/i, longer_alt: Identifier })
const Relation = createToken({ name: 'Relation', pattern: /\brel\b/i, longer_alt: Identifier })
const True = createToken({ name: 'True', pattern: /\btrue\b/i, longer_alt: Identifier })
const Type = createToken({ name: 'Type', pattern: /\btype\b/i, longer_alt: Identifier })
const Unique = createToken({ name: 'Unique', pattern: /\bunique\b/i, longer_alt: Identifier })
const keywordTokens: TokenType[] = [As, Check, False, Index, Namespace, Null, Nullable, PrimaryKey, Relation, True, Type, Unique]

// chars
const Asterisk = createToken({ name: 'Asterisk', pattern: /\*/ })
const BracketLeft = createToken({ name: 'BracketLeft', pattern: /\[/ })
const BracketRight = createToken({ name: 'BracketRight', pattern: /]/ })
const Colon = createToken({ name: 'Colon', pattern: /:/ })
const Comma = createToken({ name: 'Comma', pattern: /,/ })
const CurlyLeft = createToken({ name: 'CurlyLeft', pattern: /\{/ })
const CurlyRight = createToken({ name: 'CurlyRight', pattern: /}/ })
const Dash = createToken({ name: 'Dash', pattern: /-/ })
const Dot = createToken({ name: 'Dot', pattern: /\./ })
const Equal = createToken({ name: 'Equal', pattern: /=/ })
const GreaterThan = createToken({ name: 'GreaterThan', pattern: />/ })
const LowerThan = createToken({ name: 'LowerThan', pattern: /</ })
const ParenLeft = createToken({ name: 'ParenLeft', pattern: /\(/ })
const ParenRight = createToken({ name: 'ParenRight', pattern: /\)/ })
const charTokens: TokenType[] = [Asterisk, BracketLeft, BracketRight, Colon, Comma, CurlyLeft, CurlyRight, Dash, Dot, Equal, GreaterThan, LowerThan, ParenLeft, ParenRight]

// legacy tokens
const ForeignKey = createToken({ name: 'ForeignKey', pattern: /\bfk\b/i, longer_alt: Identifier })
const legacyTokens: TokenType[] = [ForeignKey]

// token order is important as they are tried in order, so the Identifier must be last
const allTokens: TokenType[] = [WhiteSpace, NewLine, ...charTokens, ...keywordTokens, ...legacyTokens, ...valueTokens, Expression, Identifier, DocMultiline, Doc, Comment]

const defaultPos: number = -1 // used when error position is undefined

class AmlParser extends EmbeddedActionsParser {
    // top level
    amlRule: () => AmlAst
    // statements
    statementRule: () => StatementAst
    namespaceStatementRule: () => NamespaceStatement
    entityRule: () => EntityStatement
    relationRule: () => RelationStatement
    typeRule: () => TypeStatement
    emptyStatementRule: () => EmptyStatement
    // clauses
    attributeRule: () => AttributeAstFlat
    // basic parts
    entityRefRule: () => EntityRefAst
    attributeRefRule: () => AttributeRefAst
    attributeRefCompositeRule: () => AttributeRefCompositeAst
    attributePathRule: () => AttributePathAst
    attributeValueRule: () => AttributeValueAst
    extraRule: () => ExtraAst
    propertiesRule: () => PropertiesAst
    docRule: () => DocToken
    commentRule: () => CommentToken
    // elements
    expressionRule: () => ExpressionToken
    identifierRule: () => IdentifierToken
    integerRule: () => IntegerToken
    decimalRule: () => DecimalToken
    booleanRule: () => BooleanToken
    nullRule: () => NullToken

    constructor(tokens: TokenType[], recovery: boolean) {
        super(tokens, {recoveryEnabled: recovery})
        const $ = this

        // statements

        this.amlRule = $.RULE<() => AmlAst>('amlRule', () => {
            let stmts: StatementAst[] = []
            $.MANY(() => stmts.push($.SUBRULE($.statementRule)))
            return stmts.filter(isNotUndefined) // can be undefined on invalid input :/
        })

        this.statementRule = $.RULE<() => StatementAst>('statementRule', () => $.OR([
            {ALT: () => $.SUBRULE($.namespaceStatementRule)},
            {ALT: () => $.SUBRULE($.entityRule)},
            {ALT: () => $.SUBRULE($.relationRule)},
            {ALT: () => $.SUBRULE($.typeRule)},
            {ALT: () => $.SUBRULE($.emptyStatementRule)},
        ]))

        this.namespaceStatementRule = $.RULE<() => NamespaceStatement>('namespaceStatementRule', () => {
            const keyword = $.CONSUME(Namespace)
            $.SUBRULE(whitespaceRule)
            const namespace = $.OPTION(() => $.SUBRULE(namespaceRule)) || {}
            const extra = $.SUBRULE($.extraRule)
            $.CONSUME(NewLine)
            return {statement: 'Namespace', line: keyword.startLine || defaultPos, ...namespace, ...extra}
        })

        this.entityRule = $.RULE<() => EntityStatement>('entityRule', () => {
            const {entity, ...namespace} = $.SUBRULE($.entityRefRule)
            const view = $.OPTION(() => $.CONSUME(Asterisk))
            $.SUBRULE(whitespaceRule)
            const alias = $.OPTION2(() => {
                $.CONSUME(As)
                $.CONSUME(WhiteSpace)
                return $.SUBRULE($.identifierRule)
            })
            $.SUBRULE2(whitespaceRule)
            const extra = $.SUBRULE($.extraRule)
            $.CONSUME(NewLine)
            const attrs: AttributeAstFlat[] = []
            $.MANY(() => {
                const attr = $.SUBRULE($.attributeRule)
                if (attr?.name?.value) attrs.push(attr) // name can be '' on invalid input :/
            })
            return removeEmpty({statement: 'Entity' as const, name: entity, view: view ? tokenInfo(view) : undefined, ...namespace, alias, ...extra, attrs: nestAttributes(attrs)})
        })

        this.emptyStatementRule = $.RULE<() => EmptyStatement>('emptyStatementRule', () => {
            $.SUBRULE(whitespaceRule)
            const comment = $.OPTION(() => $.SUBRULE($.commentRule))
            $.CONSUME(NewLine)
            return removeUndefined({statement: 'Empty' as const, comment})
        })

        this.relationRule = $.RULE<() => RelationStatement>('relationRule', () => {
            const warning = $.OR([
                {ALT: () => {$.CONSUME(Relation); return undefined}},
                {ALT: () => tokenInfoLegacy($.CONSUME(ForeignKey), '"fk" is legacy, replace it with "rel"')}
            ])
            $.CONSUME(WhiteSpace)
            const src = $.SUBRULE($.attributeRefCompositeRule)
            $.SUBRULE(whitespaceRule)
            const {ref, srcCardinality, refCardinality, polymorphic} = $.SUBRULE(attributeRelationRule) || {} // returns undefined on invalid input :/
            $.SUBRULE2(whitespaceRule)
            const extra = $.SUBRULE($.extraRule)
            $.CONSUME(NewLine)
            return removeUndefined({statement: 'Relation' as const, src, ref, srcCardinality, refCardinality, polymorphic, ...extra, warning})
        })

        this.typeRule = $.RULE<() => TypeStatement>('typeRule', () => {
            $.CONSUME(Type)
            $.CONSUME(WhiteSpace)
            const {entity, ...namespace} = $.SUBRULE(this.entityRefRule) || {} // returns undefined on invalid input :/
            $.SUBRULE(whitespaceRule)
            const content = $.OPTION(() => $.OR([
                {ALT: () => $.SUBRULE(typeEnumRule)},
                {ALT: () => $.SUBRULE(typeStructRule)},
                {ALT: () => $.SUBRULE(typeCustomRule)},
                {ALT: () => $.SUBRULE(typeAliasRule)},
            ]))
            $.SUBRULE2(whitespaceRule)
            const extra = $.SUBRULE($.extraRule)
            $.CONSUME(NewLine)
            /* if (content === undefined) {
                const attrs: AttributeAstFlat[] = []
                // FIXME: $.MANY fails with `TypeError: Cannot read properties of undefined (reading 'call')` at recognizer_engine.ts:517:30 (manyInternalLogic), before calling the callback, no idea why :/
                $.MANY(() => attrs.push($.SUBRULE($.attributeRule)))
                if (attrs.length > 0) content = {kind: 'struct', attrs: nestAttributes(attrs)}
            } */
            return {statement: 'Type', ...namespace, name: entity, content, ...extra}
        })

        // clauses

        this.attributeRule = $.RULE<() => AttributeAstFlat>('attributeRule', () => {
            const spaces = $.CONSUME(WhiteSpace)
            const depth = Math.round(spaces.image.split('').reduce((i, c) => c === '\t' ? i + 1 : i + 0.5, 0)) - 1
            const nesting = {...tokenInfo(spaces), depth}
            const attr = $.SUBRULE(attributeInnerRule)
            $.SUBRULE(whitespaceRule)
            const relation = $.OPTION(() => $.SUBRULE(attributeRelationRule))
            $.SUBRULE2(whitespaceRule)
            const extra = $.SUBRULE($.extraRule)
            $.CONSUME(NewLine)
            return removeUndefined({...attr, nesting, relation, ...extra})
        })
        const attributeInnerRule = $.RULE<() => AttributeAstFlat>('attributeInnerRule', () => {
            const name = $.SUBRULE($.identifierRule)
            $.SUBRULE(whitespaceRule)
            const {type, enumValues, defaultValue} = $.SUBRULE(attributeTypeRule) || {} // returns undefined on invalid input :/
            $.SUBRULE2(whitespaceRule)
            const nullable = $.OPTION(() => $.CONSUME(Nullable))
            $.SUBRULE3(whitespaceRule)
            const constraints = $.SUBRULE(attributeConstraintsRule)
            const nesting = {depth: 0, offset: {start: 0, end: 0}, position: {start: {line: 0, column: 0}, end: {line: 0, column: 0}}} // unused placeholder
            return removeUndefined({nesting, name, type, enumValues, defaultValue, nullable: nullable ? tokenInfo(nullable) : undefined, ...constraints})
        }, {resyncEnabled: true})
        const attributeTypeRule = $.RULE<() => AttributeTypeAst>('attributeTypeRule', () => {
            const res = $.OPTION(() => {
                const type = $.SUBRULE($.identifierRule)
                const enumValues = $.OPTION2(() => {
                    $.CONSUME(ParenLeft)
                    const values: AttributeValueAst[] = []
                    $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => {
                        $.SUBRULE(whitespaceRule)
                        values.push($.SUBRULE($.attributeValueRule))
                        $.SUBRULE2(whitespaceRule)
                    }})
                    $.CONSUME(ParenRight)
                    return values.filter(isNotUndefined) // can be undefined on invalid input :/
                })
                const defaultValue = $.OPTION3(() => {
                    $.CONSUME(Equal)
                    return $.SUBRULE2($.attributeValueRule)
                })
                return {type, enumValues, defaultValue}
            })
            return {type: res?.type, enumValues: res?.enumValues, defaultValue: res?.defaultValue}
        })
        const attributeConstraintsRule = $.RULE<() => AttributeConstraintsAst>('attributeConstraintsRule', () => {
            const primaryKey = $.OPTION(() => $.SUBRULE(attributePkRule))
            $.SUBRULE(whitespaceRule)
            const unique = $.OPTION2(() => $.SUBRULE(attributeUniqueRule))
            $.SUBRULE2(whitespaceRule)
            const index = $.OPTION3(() => $.SUBRULE(attributeIndexRule))
            $.SUBRULE3(whitespaceRule)
            const check = $.OPTION4(() => $.SUBRULE(attributeCheckRule))
            return removeUndefined({primaryKey, index, unique, check})
        })
        const attributePkRule = $.RULE<() => AttributeConstraintAst>('attributePkRule', () => {
            const token = $.CONSUME(PrimaryKey)
            $.SUBRULE(whitespaceRule)
            const name = $.OPTION(() => {
                $.CONSUME(Equal)
                $.SUBRULE2(whitespaceRule)
                const res = $.SUBRULE($.identifierRule)
                $.SUBRULE3(whitespaceRule)
                return res
            })
            return removeUndefined({keyword: tokenInfo(token), name})
        })
        const attributeIndexRule = $.RULE<() => AttributeConstraintAst>('attributeIndexRule', () => {
            const token = $.CONSUME(Index)
            $.SUBRULE(whitespaceRule)
            const name = $.OPTION(() => {
                $.CONSUME(Equal)
                $.SUBRULE2(whitespaceRule)
                const res = $.SUBRULE($.identifierRule)
                $.SUBRULE3(whitespaceRule)
                return res
            })
            return removeUndefined({keyword: tokenInfo(token), name})
        })
        const attributeUniqueRule = $.RULE<() => AttributeConstraintAst>('attributeUniqueRule', () => {
            const token = $.CONSUME(Unique)
            $.SUBRULE(whitespaceRule)
            const name = $.OPTION(() => {
                $.CONSUME(Equal)
                $.SUBRULE2(whitespaceRule)
                const res = $.SUBRULE($.identifierRule)
                $.SUBRULE3(whitespaceRule)
                return res
            })
            return removeUndefined({keyword: tokenInfo(token), name})
        })
        const attributeCheckRule = $.RULE<() => AttributeCheckAst>('attributeCheckRule', () => {
            const token = $.CONSUME(Check)
            $.SUBRULE(whitespaceRule)
            const predicate = $.OPTION(() => {
                $.CONSUME(ParenLeft)
                const res = $.SUBRULE($.expressionRule)
                $.CONSUME(ParenRight)
                $.SUBRULE2(whitespaceRule)
                return res
            })
            const name = $.OPTION2(() => {
                $.CONSUME(Equal)
                $.SUBRULE3(whitespaceRule)
                const res = $.SUBRULE($.identifierRule)
                $.SUBRULE4(whitespaceRule)
                return res
            })
            if (!predicate && name && [' ', '<', '>', '=', 'IN'].some(c => name.value.includes(c))) {
                // no definition and a name that look like a predicate => switch to the legacy syntax (predicate was in the name)
                const def = {...positionStartAdd(name, -1), token: 'Expression' as const, issues: [legacy(`"=${name.value}" is the legacy way, use expression instead "(\`${name.value}\`)"`)]}
                return removeUndefined({keyword: tokenInfo(token), predicate: def})
            } else {
                return removeUndefined({keyword: tokenInfo(token), predicate, name})
            }
        })
        const attributeRelationRule = $.RULE<() => AttributeRelationAst>('attributeRelationRule', () => {
            const {srcCardinality, refCardinality, polymorphic, warning} = $.OR([
                {ALT: () => {
                    const refCardinality = $.SUBRULE(relationCardinalityRule)
                    const polymorphic = $.OPTION(() => $.SUBRULE(relationPolymorphicRule))
                    const srcCardinality = $.SUBRULE2(relationCardinalityRule)
                    return {srcCardinality, refCardinality, polymorphic, warning: undefined}
                }},
                {ALT: () => {
                    const warning = tokenInfoLegacy($.CONSUME(ForeignKey), '"fk" is legacy, replace it with "->"')
                    return {srcCardinality: 'n' as const, refCardinality: '1' as const, polymorphic: undefined, warning}
                }}
            ])
            $.SUBRULE(whitespaceRule)
            const ref = $.SUBRULE2($.attributeRefCompositeRule)
            return removeUndefined({ref, srcCardinality, refCardinality, polymorphic, warning})
        })

        const relationCardinalityRule = $.RULE<() => RelationCardinality>('relationCardinalityRule', () => $.OR([
            {ALT: () => { $.CONSUME(Dash); return '1' }},
            {ALT: () => { $.CONSUME(LowerThan); return 'n' }},
            {ALT: () => { $.CONSUME(GreaterThan); return 'n' }},
        ]))
        const relationPolymorphicRule = $.RULE<() => RelationPolymorphicAst>('relationPolymorphicRule', () => {
            const attr = $.SUBRULE($.attributePathRule)
            $.CONSUME(Equal)
            const value = $.SUBRULE($.attributeValueRule)
            return {attr, value}
        })

        const typeAliasRule = $.RULE<() => TypeAliasAst>('typeAliasRule', () => ({kind: 'alias', name: $.SUBRULE($.identifierRule)}))
        const typeEnumRule = $.RULE<() => TypeEnumAst>('typeEnumRule', () => {
            $.CONSUME(ParenLeft)
            const values: AttributeValueAst[] = []
            $.MANY_SEP({SEP: Comma, DEF: () => {
                $.SUBRULE(whitespaceRule)
                values.push($.SUBRULE($.attributeValueRule))
                $.SUBRULE2(whitespaceRule)
            }})
            $.CONSUME(ParenRight)
            return {kind: 'enum', values}
        })
        const typeStructRule = $.RULE<() => TypeStructAst>('typeStructRule', () => {
            $.CONSUME(CurlyLeft)
            const attrs: AttributeAstFlat[] = []
            $.MANY_SEP({SEP: Comma, DEF: () => {
                $.SUBRULE(whitespaceRule)
                attrs.push($.SUBRULE(attributeInnerRule))
                $.SUBRULE2(whitespaceRule)
            }})
            $.CONSUME(CurlyRight)
            return {kind: 'struct', attrs: nestAttributes(attrs)}
        })
        const typeCustomRule = $.RULE<() => TypeCustomAst>('typeCustomRule', () => ({kind: 'custom', definition: $.SUBRULE($.expressionRule)}))

        // basic parts

        const namespaceRule = $.RULE<() => NamespaceRefAst>('namespaceRule', () => {
            const first = $.SUBRULE($.identifierRule)
            const second = $.OPTION(() => ({dot: $.CONSUME(Dot), id: $.OPTION2(() => $.SUBRULE2($.identifierRule))}))
            const third = $.OPTION3(() => ({dot: $.CONSUME2(Dot), id: $.OPTION4(() => $.SUBRULE3($.identifierRule))}))
            $.SUBRULE(whitespaceRule)
            if (second && third) return removeUndefined({database: first, catalog: second.id, schema: third.id})
            if (second) return removeUndefined({catalog: first, schema: second.id})
            return {schema: first}
        })

        this.entityRefRule = $.RULE<() => EntityRefAst>('entityRefRule', () => {
            const first = $.SUBRULE($.identifierRule)
            const second = $.OPTION(() => ({dot: $.CONSUME(Dot), id: $.OPTION2(() => $.SUBRULE2($.identifierRule))}))
            const third = $.OPTION3(() => ({dot: $.CONSUME2(Dot), id: $.OPTION4(() => $.SUBRULE3($.identifierRule))}))
            const fourth = $.OPTION5(() => ({dot: $.CONSUME3(Dot), id: $.OPTION6(() => $.SUBRULE4($.identifierRule))}))
            $.SUBRULE(whitespaceRule)
            if (second && third && fourth && fourth.id) return removeUndefined({database: first, catalog: second.id, schema: third.id, entity: fourth.id})
            if (second && third && third.id) return removeUndefined({catalog: first, schema: second.id, entity: third.id})
            if (second && second.id) return removeUndefined({schema: first, entity: second.id})
            return {entity: first}
        })

        this.attributeRefRule = $.RULE<() => AttributeRefAst>('attributeRefRule', () => {
            const entity = $.SUBRULE($.entityRefRule)
            return $.OR([
                {ALT: () => {
                    $.CONSUME(ParenLeft)
                    const attr = $.SUBRULE($.attributePathRule)
                    $.CONSUME(ParenRight)
                    return {...entity, attr}
                }},
                {ALT: () => {
                    // legacy fallback
                    if (!entity.schema) return removeUndefined({schema: entity.catalog, entity: entity.schema, attr: entity.entity}) // not finished, so no warning
                    const path = $.SUBRULE(legacyAttributePathRule)
                    const v1 = `${entity.catalog ? entity.catalog.value + '.' : ''}${entity.schema.value}.${entity.entity.value}${path.map(p => ':' + p.value).join('')}`
                    const v2 = `${entity.catalog ? entity.catalog.value + '.' : ''}${entity.schema.value}(${entity.entity.value}${path.map(p => '.' + p.value).join('')})`
                    const warning: TokenInfo = {
                        ...mergePositions([entity.catalog, entity.schema, entity.entity, ...path].filter(isNotUndefined)),
                        issues: [legacy(`"${v1}" is the legacy way, use "${v2}" instead`)]
                    }
                    return removeUndefined({schema: entity.catalog, entity: entity.schema, attr: removeEmpty({...entity.entity, path}), warning})
                }}
            ])
        })

        this.attributeRefCompositeRule = $.RULE<() => AttributeRefCompositeAst>('attributeRefCompositeRule', () => {
            const entity = $.SUBRULE($.entityRefRule)
            return $.OR([
                {ALT: () => {
                    $.CONSUME(ParenLeft)
                    const attrs: AttributePathAst[] = []
                    $.AT_LEAST_ONE_SEP({SEP: Comma, DEF: () => {
                        $.SUBRULE(whitespaceRule)
                        attrs.push($.SUBRULE($.attributePathRule))
                        $.SUBRULE2(whitespaceRule)
                    }})
                    $.CONSUME(ParenRight)
                    return {...entity, attrs}
                }},
                {ALT: () => {
                    // legacy fallback
                    if (!entity.schema) return removeUndefined({entity: entity.entity, attrs: []}) // relation without attributes
                    const path = $.SUBRULE(legacyAttributePathRule)
                    const v1 = `${entity.catalog ? entity.catalog.value + '.' : ''}${entity.schema.value}.${entity.entity.value}${path.map(p => ':' + p.value).join('')}`
                    const v2 = `${entity.catalog ? entity.catalog.value + '.' : ''}${entity.schema.value}(${entity.entity.value}${path.map(p => '.' + p.value).join('')})`
                    const warning: TokenInfo = {
                        ...mergePositions([entity.catalog, entity.schema, entity.entity, ...path].filter(isNotUndefined)),
                        issues: [legacy(`"${v1}" is the legacy way, use "${v2}" instead`)]
                    }
                    return removeUndefined({schema: entity.catalog, entity: entity.schema, attrs: [removeEmpty({...entity.entity, path})], warning})
                }}
            ])
        })

        this.attributePathRule = $.RULE<() => AttributePathAst>('attributePathRule', () => {
            const attr = $.SUBRULE($.identifierRule)
            const path: IdentifierToken[] = []
            $.MANY(() => {
                $.CONSUME(Dot)
                path.push($.SUBRULE2($.identifierRule))
            })
            return removeEmpty({...attr, path})
        })
        const legacyAttributePathRule = $.RULE<() => IdentifierToken[]>('legacyAttributePathRule', () => {
            const path: IdentifierToken[] = []
            $.MANY(() => {
                $.CONSUME(Colon)
                path.push($.SUBRULE($.identifierRule))
            })
            return path
        })

        this.attributeValueRule = $.RULE<() => AttributeValueAst>('attributeValueRule', () => $.OR([
            {ALT: () => $.SUBRULE($.nullRule)},
            {ALT: () => $.SUBRULE($.integerRule)},
            {ALT: () => $.SUBRULE($.decimalRule)},
            {ALT: () => $.SUBRULE($.booleanRule)},
            {ALT: () => $.SUBRULE($.expressionRule)},
            {ALT: () => $.SUBRULE($.identifierRule)},
        ]))

        this.extraRule = $.RULE<() => ExtraAst>('extraRule', () => {
            const properties = $.OPTION(() => $.SUBRULE($.propertiesRule))
            $.SUBRULE(whitespaceRule)
            const doc = $.OPTION2(() => $.SUBRULE($.docRule))
            $.SUBRULE2(whitespaceRule)
            const comment = $.OPTION3(() => $.SUBRULE($.commentRule))
            return removeUndefined({properties, doc, comment})
        })

        this.propertiesRule = $.RULE<() => PropertiesAst>('propertiesRule', () => {
            $.CONSUME(CurlyLeft)
            const props: PropertiesAst = []
            $.MANY_SEP({SEP: Comma, DEF: () => {
                $.SUBRULE(whitespaceRule)
                props.push($.SUBRULE(propertyRule))
                $.SUBRULE2(whitespaceRule)
            }})
            $.CONSUME(CurlyRight)
            return props.filter(isNotUndefined) // can be undefined on invalid input :/
        })
        const propertyRule = $.RULE<() => PropertyAst>('propertyRule', () => {
            const key = $.SUBRULE($.identifierRule)
            $.SUBRULE(whitespaceRule)
            const value = $.OPTION(() => {
                const sep = $.OR([
                    {ALT: () => tokenInfo($.CONSUME(Colon))},
                    {ALT: () => tokenInfoLegacy($.CONSUME(Equal), '"=" is legacy, replace it with ":"')},
                ])
                $.SUBRULE2(whitespaceRule)
                return {sep, value: $.SUBRULE(propertyValueRule)}
            })
            return {key, ...value}
        })
        const propertyValueRule = $.RULE<() => PropertyValueAst>('propertyValueRule', () => $.OR([
            {ALT: () => $.SUBRULE($.nullRule)},
            {ALT: () => $.SUBRULE($.decimalRule)},
            {ALT: () => $.SUBRULE($.integerRule)},
            {ALT: () => $.SUBRULE($.booleanRule)},
            {ALT: () => $.SUBRULE($.expressionRule)},
            {ALT: () => $.SUBRULE($.identifierRule)},
            {ALT: () => {
                $.CONSUME(BracketLeft)
                const values: PropertyValueAst[] = []
                $.MANY_SEP({SEP: Comma, DEF: () => {
                    $.SUBRULE(whitespaceRule)
                    values.push($.SUBRULE(propertyValueRule))
                    $.SUBRULE2(whitespaceRule)
                }})
                $.CONSUME(BracketRight)
                return values.filter(isNotUndefined) // can be undefined on invalid input :/
            }},
        ]))

        this.docRule = $.RULE<() => DocToken>('docRule', () => $.OR([
            {ALT: () => {
                const token = $.CONSUME(DocMultiline)
                return {token: 'Doc', value: stripIndent(token.image.slice(3, -3)), ...tokenPosition(token), multiLine: true}
            }},
            {ALT: () => {
                const token = $.CONSUME(Doc)
                return {token: 'Doc', value: removeQuotes(token.image.slice(1).trim().replaceAll(/\\#/g, '#')), ...tokenPosition(token)}
            }}
        ]))

        this.commentRule = $.RULE<() => CommentToken>('commentRule', () => {
            const token = $.CONSUME(Comment)
            return {token: 'Comment', value: token.image.slice(1).trim(), ...tokenPosition(token)}
        })

        // elements

        this.expressionRule = $.RULE<() => ExpressionToken>('expressionRule', () => {
            const token = $.CONSUME(Expression)
            return {token: 'Expression', value: token.image.slice(1, -1), ...tokenPosition(token)}
        })

        this.identifierRule = $.RULE<() => IdentifierToken>('identifierRule', () => {
            const token = $.CONSUME(Identifier)
            if (token.image.startsWith('"') && token.image.endsWith('"')) {
                return {token: 'Identifier', value: token.image.slice(1, -1).replaceAll(/\\"/g, '"'), ...tokenPosition(token), quoted: true}
            } else {
                return {token: 'Identifier', value: token.image, ...tokenPosition(token)}
            }
        })

        this.integerRule = $.RULE<() => IntegerToken>('integerRule', () => {
            const neg = $.OPTION(() => $.CONSUME(Dash))
            const token = $.CONSUME(Integer)
            return neg ? {token: 'Integer', ...tokenInfo2(neg, token), value: parseInt(neg.image + token.image)} : {token: 'Integer', ...tokenInfo(token), value: parseInt(token.image)}
        })

        this.decimalRule = $.RULE<() => DecimalToken>('decimalRule', () => {
            const neg = $.OPTION(() => $.CONSUME(Dash))
            const token = $.CONSUME(Decimal)
            return neg ? {token: 'Decimal', ...tokenInfo2(neg, token), value: parseFloat(neg.image + token.image)} : {token: 'Decimal', ...tokenInfo(token), value: parseFloat(token.image)}
        })

        this.booleanRule = $.RULE<() => BooleanToken>('booleanRule', () => $.OR([
            {ALT: () => ({token: 'Boolean', value: true, ...tokenInfo($.CONSUME(True))})},
            {ALT: () => ({token: 'Boolean', value: false, ...tokenInfo($.CONSUME(False))})},
        ]))

        this.nullRule = $.RULE<() => NullToken>('nullRule', () => ({token: 'Null', ...tokenInfo($.CONSUME(Null))}))

        const whitespaceRule = $.RULE<() => IToken | undefined>('whitespaceRule', () => $.OPTION(() => $.CONSUME(WhiteSpace)))

        this.performSelfAnalysis()
    }
}

const lexer = new Lexer(allTokens)
const parserStrict = new AmlParser(allTokens, false)
const parserWithRecovery = new AmlParser(allTokens, true)

// exported only for tests, use the `parse` function instead
export function parseRule<T>(parse: (p: AmlParser) => T, input: string, strict: boolean = false): ParserResult<T> {
    const lexingResult = lexer.tokenize(input)
    const parser = strict ? parserStrict : parserWithRecovery
    parser.input = lexingResult.tokens // "input" is a setter which will reset the parser's state.
    const res = parse(parser)
    const errors = lexingResult.errors.map(formatLexerError).concat(parser.errors.map(formatParserError))
    return new ParserResult(res, errors)
}

export function parseAmlAst(input: string, opts: { strict?: boolean }): ParserResult<AmlAst> {
    return parseRule(p => p.amlRule(), input, opts.strict || false)
}

function formatLexerError(err: ILexingError): ParserError {
    return {
        message: err.message,
        kind: 'LexingError',
        level: ParserErrorLevel.enum.error,
        offset: {start: err.offset, end: err.offset + err.length},
        position: {
            start: {line: err.line || defaultPos, column: err.column || defaultPos},
            end: {line: err.line || defaultPos, column: (err.column || defaultPos) + err.length}
        }
    }
}

function formatParserError(err: IRecognitionException): ParserError {
    return {message: err.message, kind: err.name, level: ParserErrorLevel.enum.error, ...tokenInfo(err.token)}
}

function tokenInfo(token: IToken, issues?: TokenIssue[]): TokenInfo {
    return removeEmpty({...tokenPosition(token), issues})
}

function tokenInfo2(start: IToken | undefined, end: IToken | undefined, issues?: TokenIssue[]): TokenInfo {
    return removeEmpty({...mergePositions([start, end].map(t => t ? tokenPosition(t) : undefined)), issues})
}

function tokenInfoLegacy(token: IToken, message: string): TokenInfo {
    return tokenInfo(token, [legacy(message)])
}

function tokenPosition(token: IToken): TokenPosition {
    return {
        offset: {start: pos(token.startOffset), end: pos(token.endOffset)},
        position: {
            start: {line: pos(token.startLine), column: pos(token.startColumn)},
            end: {line: pos(token.endLine), column: pos(token.endColumn)}
        }
    }
}

function pos(value: number | undefined): number {
    return value !== undefined && !isNaN(value) ? value : defaultPos
}

// utils functions

export function nestAttributes(attributes: AttributeAstFlat[]): AttributeAstNested[] {
    const results: AttributeAstNested[] = []
    let path: IdentifierToken[] = []
    let parents: AttributeAstNested[] = []
    let curNesting = 0
    attributes.forEach(function(attribute) {
        if (attribute === undefined) return undefined // can be undefined on invalid input :/
        if (!attribute.nesting) return undefined // empty during recording phase... :/
        const {nesting, name, ...values} = attribute
        if (nesting.depth === 0 || parents.length === 0) { // empty parents is when first attr is not at nesting 0
            curNesting = 0
            path = [name]
            parents = [{path, ...values}]
            results.push(parents[0]) // add top level attrs to results
        } else if (nesting.depth > curNesting) { // deeper: append to `path` & `parents`
            curNesting = curNesting + 1 // go only one level deeper at the time (even if nesting is higher)
            const warning = nesting.depth > curNesting ? {offset: nesting.offset, position: nesting.position, issues: [...nesting.issues || [], badIndent(curNesting, nesting.depth)]} : undefined
            path = [...path, name]
            parents = [...parents, removeUndefined({path, ...values, warning})]
            parents[parents.length - 2].attrs = [...(parents[parents.length - 2].attrs || []), parents[parents.length - 1]] // add to parent
        } else if (nesting.depth <= curNesting) { // same level or up: replace n+1 last values in `path` & `parents`
            const n = curNesting - nesting.depth
            curNesting = nesting.depth
            path = [...path.slice(0, -(n + 1)), name]
            parents = [...parents.slice(0, -(n + 1)), {path, ...values}]
            parents[parents.length - 2].attrs = [...(parents[parents.length - 2].attrs || []), parents[parents.length - 1]] // add to parent
        } else { // should never happen, `nesting` is always > or <= to `curNesting`
            throw new Error(`Should never happen (nesting: ${nesting}, curNesting: ${curNesting})`)
        }
    })
    return results
}
