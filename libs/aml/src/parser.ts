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
import {mergePositions, ParserError, ParserResult, removeQuotes, TokenPosition} from "@azimutt/models";
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
    EntityStatement,
    EntityRefAst,
    ExpressionToken,
    ExtraAst,
    IdentifierToken,
    IntegerToken,
    NamespaceStatement,
    NullToken,
    PropertiesAst,
    PropertyAst,
    PropertyValueAst,
    RelationStatement,
    RelationCardinalityAst,
    RelationPolymorphicAst,
    StatementAst,
    TokenInfo,
    TokenIssue,
    TypeAliasAst,
    TypeStatement,
    TypeCustomAst,
    TypeEnumAst,
    TypeStructAst
} from "./ast";
import {badIndent, legacy} from "./errors";

// special
const WhiteSpace = createToken({name: 'WhiteSpace', pattern: /[ \t]+/})
const Identifier = createToken({ name: 'Identifier', pattern: /[a-zA-Z_][a-zA-Z0-9_#]*|"([^\\"]|\\\\|\\")*"/ })
const Expression = createToken({ name: 'Expression', pattern: /`[^`]+`/ })
const Doc = createToken({ name: 'Doc', pattern: /\|(\s+"([^\\"]|\\\\|\\")*"|[^#\n]*)/ })
const DocMultiline = createToken({ name: 'DocMultiline', pattern: /\|\|\|[^]*?\|\|\|/, line_breaks: true })
const Comment = createToken({ name: 'Comment', pattern: /#[^\n]*/ })

// values
const Null = createToken({ name: 'Null', pattern: /null/i })
const Decimal = createToken({ name: 'Decimal', pattern: /\d+\.\d+/ })
const Integer = createToken({ name: 'Integer', pattern: /\d+/, longer_alt: Decimal })
const String = createToken({ name: 'String', pattern: /'([^\\']|\\\\|\\')*'/ })
const Boolean = createToken({ name: 'Boolean', pattern: /true|false/i, longer_alt: Identifier })
const valueTokens: TokenType[] = [Integer, Decimal, String, Boolean, Null]

// keywords
const Namespace = createToken({ name: 'Namespace', pattern: /namespace/i, longer_alt: Identifier })
const As = createToken({ name: 'As', pattern: /as/i, longer_alt: Identifier })
const Nullable = createToken({ name: 'Nullable', pattern: /nullable/i, longer_alt: Identifier })
const PrimaryKey = createToken({ name: 'PrimaryKey', pattern: /pk/i, longer_alt: Identifier })
const Index = createToken({ name: 'Index', pattern: /index/i, longer_alt: Identifier })
const Unique = createToken({ name: 'Unique', pattern: /unique/i, longer_alt: Identifier })
const Check = createToken({ name: 'Check', pattern: /check/i, longer_alt: Identifier })
const Relation = createToken({ name: 'Relation', pattern: /rel/i, longer_alt: Identifier })
const Type = createToken({ name: 'Type', pattern: /type/i, longer_alt: Identifier })
const keywordTokens: TokenType[] = [Namespace, As, Nullable, PrimaryKey, Index, Unique, Check, Relation, Type]

// chars
const NewLine = createToken({ name: 'NewLine', pattern: /\r?\n/ })
const Asterisk = createToken({ name: 'Asterisk', pattern: /\*/ })
const Dot = createToken({ name: 'Dot', pattern: /\./ })
const Comma = createToken({ name: 'Comma', pattern: /,/ })
const Colon = createToken({ name: 'Colon', pattern: /:/ })
const Equal = createToken({ name: 'Equal', pattern: /=/ })
const Dash = createToken({ name: 'Dash', pattern: /-/ })
const GreaterThan = createToken({ name: 'GreaterThan', pattern: />/ })
const LowerThan = createToken({ name: 'LowerThan', pattern: /</ })
const LParen = createToken({ name: 'LParen', pattern: /\(/ })
const RParen = createToken({ name: 'RParen', pattern: /\)/ })
const LBracket = createToken({ name: 'LBracket', pattern: /\[/ })
const RBracket = createToken({ name: 'RBracket', pattern: /]/ })
const LCurly = createToken({ name: 'LCurly', pattern: /\{/ })
const RCurly = createToken({ name: 'RCurly', pattern: /}/ })
const charTokens: TokenType[] = [Asterisk, Dot, Comma, Colon, Equal, Dash, GreaterThan, LowerThan, LParen, RParen, LBracket, RBracket, LCurly, RCurly]

// legacy tokens
const ForeignKey = createToken({ name: 'ForeignKey', pattern: /fk/i })
const legacyTokens: TokenType[] = [ForeignKey]

// token order is important as they are tried in order, so the Identifier must be last
const allTokens: TokenType[] = [WhiteSpace, NewLine, ...charTokens, ...keywordTokens, ...legacyTokens, ...valueTokens, Expression, Identifier, DocMultiline, Doc, Comment]

const defaultPos: number = -1 // used when error position is undefined

class AmlParser extends EmbeddedActionsParser {
    // common
    nullRule: () => NullToken
    decimalRule: () => DecimalToken
    integerRule: () => IntegerToken
    booleanRule: () => BooleanToken
    expressionRule: () => ExpressionToken
    identifierRule: () => IdentifierToken
    docRule: () => DocToken
    commentRule: () => CommentToken
    propertiesRule: () => PropertiesAst
    extraRule: () => ExtraAst
    entityRefRule: () => EntityRefAst
    attributePathRule: () => AttributePathAst
    attributeRefRule: () => AttributeRefAst
    attributeRefCompositeRule: () => AttributeRefCompositeAst
    attributeValueRule: () => AttributeValueAst

    // namespace
    namespaceRule: () => NamespaceStatement

    // entity
    attributeRule: () => AttributeAstFlat
    entityRule: () => EntityStatement

    // relation
    relationRule: () => RelationStatement

    // type
    typeRule: () => TypeStatement

    // general
    emptyStatementRule: () => EmptyStatement
    statementRule: () => StatementAst
    amlRule: () => AmlAst

    constructor(tokens: TokenType[], recovery: boolean) {
        super(tokens, {recoveryEnabled: recovery})
        const $ = this

        // common rules
        this.nullRule = $.RULE<() => NullToken>('nullRule', () => {
            const token = $.CONSUME(Null)
            return {token: 'Null', ...tokenPosition(token)}
        })

        this.decimalRule = $.RULE<() => DecimalToken>('decimalRule', () => {
            const token = $.CONSUME(Decimal)
            return {token: 'Decimal', value: parseFloat(token.image), ...tokenPosition(token)}
        })

        this.integerRule = $.RULE<() => IntegerToken>('integerRule', () => {
            const token = $.CONSUME(Integer)
            return {token: 'Integer', value: parseInt(token.image), ...tokenPosition(token)}
        })

        this.booleanRule = $.RULE<() => BooleanToken>('booleanRule', () => {
            const token = $.CONSUME(Boolean)
            return {token: 'Boolean', value: token.image.toLowerCase() === 'true', ...tokenPosition(token)}
        })

        this.expressionRule = $.RULE<() => ExpressionToken>('expressionRule', () => {
            const token = $.CONSUME(Expression)
            return {token: 'Expression', value: token.image.slice(1, -1), ...tokenPosition(token)}
        })

        this.identifierRule = $.RULE<() => IdentifierToken>('identifierRule', () => {
            const token = $.CONSUME(Identifier)
            if (token.image.startsWith('"')) {
                return {token: 'Identifier', value: token.image.slice(1, -1).replaceAll(/\\"/g, '"'), ...tokenPosition(token)}
            } else {
                return {token: 'Identifier', value: token.image, ...tokenPosition(token)}
            }
        })

        this.docRule = $.RULE<() => DocToken>('docRule', () => {
            return $.OR([{
                ALT: () => {
                    const token = $.CONSUME(DocMultiline)
                    return {token: 'Doc', value: stripIndent(token.image.slice(3, -3)), ...tokenPosition(token)}
                }
            }, {
                ALT: () => {
                    const token = $.CONSUME(Doc)
                    return {token: 'Doc', value: removeQuotes(token.image.slice(1).trim()), ...tokenPosition(token)}
                }
            }])
        })

        this.commentRule = $.RULE<() => CommentToken>('commentRule', () => {
            const token = $.CONSUME(Comment)
            return {token: 'Comment', value: token.image.slice(1).trim(), ...tokenPosition(token)}
        })

        const propertyValueRule = $.RULE<() => PropertyValueAst>('propertyValueRule', () => {
            return $.OR([
                { ALT: () => $.SUBRULE($.nullRule) },
                { ALT: () => $.SUBRULE($.decimalRule) },
                { ALT: () => $.SUBRULE($.integerRule) },
                { ALT: () => $.SUBRULE($.booleanRule) },
                { ALT: () => $.SUBRULE($.expressionRule) },
                { ALT: () => $.SUBRULE($.identifierRule) },
                { ALT: () => {
                        $.CONSUME(LBracket)
                        const values: PropertyValueAst[] = []
                        $.MANY_SEP({
                            SEP: Comma,
                            DEF: () => {
                                $.OPTION(() => $.CONSUME(WhiteSpace))
                                values.push($.SUBRULE(propertyValueRule))
                                $.OPTION2(() => $.CONSUME2(WhiteSpace))
                            }
                        })
                        $.CONSUME(RBracket)
                        return values
                }},
            ])
        })
        const propertyRule = $.RULE<() => PropertyAst>('propertyRule', () => {
            const key = $.SUBRULE($.identifierRule)
            $.OPTION(() => $.CONSUME(WhiteSpace))
            const value = $.OPTION2(() => {
                const sep = $.OR([
                    {ALT: () => tokenInfo($.CONSUME(Colon)) },
                    {ALT: () => tokenInfoLegacy($.CONSUME(Equal), '"=" is legacy, replace it with ":"') },
                ])
                $.OPTION3(() => $.CONSUME2(WhiteSpace))
                return {sep, value: $.SUBRULE(propertyValueRule)}
            })
            return {key, ...value}
        })
        this.propertiesRule = $.RULE<() => PropertiesAst>('propertiesRule', () => {
            const props: PropertiesAst = []
            $.CONSUME(LCurly)
            $.MANY_SEP({
                SEP: Comma,
                DEF: () => {
                    $.OPTION(() => $.CONSUME(WhiteSpace))
                    props.push($.SUBRULE(propertyRule))
                    $.OPTION2(() => $.CONSUME2(WhiteSpace))
                }
            })
            $.CONSUME(RCurly)
            return props
        })

        this.extraRule = $.RULE<() => ExtraAst>('extraRule', () => {
            const properties = $.OPTION(() => $.SUBRULE($.propertiesRule))
            $.OPTION2(() => $.CONSUME(WhiteSpace))
            const doc = $.OPTION3(() => $.SUBRULE2($.docRule))
            $.OPTION4(() => $.CONSUME2(WhiteSpace))
            const comment = $.OPTION5(() => $.SUBRULE3($.commentRule))
            return removeUndefined({properties, doc, comment})
        })

        const nestedRule = $.RULE<() => IdentifierToken>('nestedRule', () => {
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

        this.attributePathRule = $.RULE<() => AttributePathAst>('attributePathRule', () => {
            const attr = $.SUBRULE($.identifierRule)
            const path: IdentifierToken[] = []
            $.MANY(() => path.push($.SUBRULE(nestedRule)))
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

        this.attributeRefRule = $.RULE<() => AttributeRefAst>('attributeRefRule', () => {
            const entity = $.SUBRULE($.entityRefRule)
            return $.OR([{
                ALT: () => {
                    $.CONSUME(LParen)
                    const attr = $.SUBRULE($.attributePathRule)
                    $.CONSUME(RParen)
                    return {...entity, attr}
                }
            }, {
                ALT: () => {
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
                }
            }])
        })

        this.attributeRefCompositeRule = $.RULE<() => AttributeRefCompositeAst>('attributeRefCompositeRule', () => {
            const entity = $.SUBRULE($.entityRefRule)
            return $.OR([{
                ALT: () => {
                    $.CONSUME(LParen)
                    const attrs: AttributePathAst[] = []
                    $.AT_LEAST_ONE_SEP({
                        SEP: Comma,
                        DEF: () => {
                            $.OPTION(() => $.CONSUME(WhiteSpace))
                            attrs.push($.SUBRULE($.attributePathRule))
                            $.OPTION2(() => $.CONSUME2(WhiteSpace))
                        }
                    })
                    $.CONSUME(RParen)
                    return {...entity, attrs}
                }
            }, {
                // legacy fallback
                ALT: () => {
                    if (!entity.schema) return removeUndefined({schema: entity.catalog, entity: entity.schema, attrs: [entity.entity]}) // not finished, so no warning
                    const path = $.SUBRULE(legacyAttributePathRule)
                    const v1 = `${entity.catalog ? entity.catalog.value + '.' : ''}${entity.schema.value}.${entity.entity.value}${path.map(p => ':' + p.value).join('')}`
                    const v2 = `${entity.catalog ? entity.catalog.value + '.' : ''}${entity.schema.value}(${entity.entity.value}${path.map(p => '.' + p.value).join('')})`
                    const warning: TokenInfo = {
                        ...mergePositions([entity.catalog, entity.schema, entity.entity, ...path].filter(isNotUndefined)),
                        issues: [legacy(`"${v1}" is the legacy way, use "${v2}" instead`)]
                    }
                    return removeUndefined({schema: entity.catalog, entity: entity.schema, attrs: [removeEmpty({...entity.entity, path})], warning})
                }
            }])
        })

        this.attributeValueRule = $.RULE<() => AttributeValueAst>('attributeValueRule', () => {
            return $.OR([
                { ALT: () => $.SUBRULE($.nullRule) },
                { ALT: () => $.SUBRULE($.integerRule) },
                { ALT: () => $.SUBRULE($.decimalRule) },
                { ALT: () => $.SUBRULE($.booleanRule) },
                { ALT: () => $.SUBRULE($.expressionRule) },
                { ALT: () => $.SUBRULE($.identifierRule) },
            ])
        })

        // namespace rules
        this.namespaceRule = $.RULE<() => NamespaceStatement>('namespaceRule', () => {
            $.CONSUME(Namespace)
            $.CONSUME(WhiteSpace)
            const first = $.SUBRULE($.identifierRule)
            const second = $.OPTION(() => $.SUBRULE(nestedRule))
            const third = $.OPTION2(() => $.SUBRULE2(nestedRule))
            $.OPTION3(() => $.CONSUME2(WhiteSpace))
            const extra = $.SUBRULE($.extraRule)
            $.CONSUME(NewLine)
            const [schema, catalog, database] = [third, second, first].filter(i => !!i)
            return removeUndefined({statement: 'Namespace' as const, schema: schema || first, catalog, database, ...extra})
        })

        // entity rules
        const attributeTypeRule = $.RULE<() => AttributeTypeAst>('attributeTypeRule', () => {
            const res = $.OPTION(() => {
                const type = $.SUBRULE($.identifierRule)
                const enumValues = $.OPTION2(() => {
                    $.CONSUME(LParen)
                    const values: AttributeValueAst[] = []
                    $.AT_LEAST_ONE_SEP({
                        SEP: Comma,
                        DEF: () => {
                            $.OPTION3(() => $.CONSUME(WhiteSpace))
                            values.push($.SUBRULE($.attributeValueRule))
                            $.OPTION4(() => $.CONSUME2(WhiteSpace))
                        }
                    })
                    $.CONSUME(RParen)
                    return values
                })
                const defaultValue = $.OPTION5(() => {
                    $.CONSUME(Equal)
                    return $.SUBRULE2($.attributeValueRule)
                })
                return {type, enumValues, defaultValue}
            })
            return {type: res?.type, enumValues: res?.enumValues, defaultValue: res?.defaultValue}
        })
        const attributeConstraintPkRule = $.RULE<() => AttributeConstraintAst>('attributeConstraintPkRule', () => {
            const token = $.CONSUME(PrimaryKey)
            $.OPTION(() => $.CONSUME(WhiteSpace))
            const name = $.OPTION2(() => {
                $.CONSUME(Equal)
                $.OPTION3(() => $.CONSUME2(WhiteSpace))
                return $.SUBRULE($.identifierRule)
            })
            return removeUndefined({keyword: tokenInfo(token), name})
        })
        const attributeConstraintIndexRule = $.RULE<() => AttributeConstraintAst>('attributeConstraintIndexRule', () => {
            const token = $.CONSUME(Index)
            $.OPTION(() => $.CONSUME(WhiteSpace))
            const name = $.OPTION2(() => {
                $.CONSUME(Equal)
                $.OPTION3(() => $.CONSUME2(WhiteSpace))
                return $.SUBRULE($.identifierRule)
            })
            return removeUndefined({keyword: tokenInfo(token), name})
        })
        const attributeConstraintUniqueRule = $.RULE<() => AttributeConstraintAst>('attributeConstraintUniqueRule', () => {
            const token = $.CONSUME(Unique)
            $.OPTION(() => $.CONSUME(WhiteSpace))
            const name = $.OPTION2(() => {
                $.CONSUME(Equal)
                $.OPTION3(() => $.CONSUME2(WhiteSpace))
                return $.SUBRULE($.identifierRule)
            })
            return removeUndefined({keyword: tokenInfo(token), name})
        })
        const attributeConstraintCheckRule = $.RULE<() => AttributeCheckAst>('attributeConstraintCheckRule', () => {
            const token = $.CONSUME(Check)
            $.OPTION(() => $.CONSUME(WhiteSpace))
            const definition = $.OPTION2(() => {
                $.CONSUME(Equal)
                $.OPTION3(() => $.CONSUME2(WhiteSpace))
                return $.OR([
                    {ALT: () => $.SUBRULE($.expressionRule)},
                    {ALT: () => {
                        const identifier = $.SUBRULE($.identifierRule)
                        return {...identifier, token: 'Expression', issues: [legacy(`"${identifier.value}" is the legacy way, use expression "\`${identifier.value}\`" instead`)]}
                    }},
                ])
            })
            return removeUndefined({keyword: tokenInfo(token), definition})
        })
        const attributeConstraintsRule = $.RULE<() => AttributeConstraintsAst>('attributeConstraintsRule', () => {
            const primaryKey = $.OPTION(() => $.SUBRULE(attributeConstraintPkRule))
            $.OPTION2(() => $.CONSUME(WhiteSpace))
            const index = $.OPTION3(() => $.SUBRULE(attributeConstraintIndexRule))
            $.OPTION4(() => $.CONSUME2(WhiteSpace))
            const unique = $.OPTION5(() => $.SUBRULE(attributeConstraintUniqueRule))
            $.OPTION6(() => $.CONSUME3(WhiteSpace))
            const check = $.OPTION7(() => $.SUBRULE(attributeConstraintCheckRule))
            return removeUndefined({primaryKey, index, unique, check})
        })
        const attributeRelationRule = $.RULE<() => AttributeRelationAst>('attributeRelationRule', () => {
            const {kind, polymorphic, warning} = $.OR([{
                ALT: () => {
                    const refCardinality = $.SUBRULE(relationCardinalityRule)
                    const polymorphic = $.OPTION(() => $.SUBRULE(relationPolymorphicRule))
                    const srcCardinality = $.SUBRULE2(relationCardinalityRule)
                    return {kind: `${srcCardinality}-${refCardinality}` as const, polymorphic, warning: undefined}
                }
            }, {
                ALT: () => {
                    const warning = tokenInfoLegacy($.CONSUME(ForeignKey), '"fk" is legacy, replace it with "->"')
                    return {kind: 'n-1', polymorphic: undefined, warning}
                }
            }])
            $.OPTION2(() => $.CONSUME(WhiteSpace))
            const ref = $.SUBRULE2($.attributeRefCompositeRule)
            return removeUndefined({kind, ref, polymorphic, warning})
        })
        const attributeRuleInner = $.RULE<() => AttributeAstFlat>('attributeRuleInner', () => {
            const name = $.SUBRULE($.identifierRule)
            $.OPTION(() => $.CONSUME2(WhiteSpace))
            const {type, enumValues, defaultValue} = $.SUBRULE(attributeTypeRule) || {} // returns undefined on invalid input :/
            $.OPTION2(() => $.CONSUME3(WhiteSpace))
            const nullable = $.OPTION3(() => $.CONSUME(Nullable))
            $.OPTION4(() => $.CONSUME4(WhiteSpace))
            const constraints = $.SUBRULE(attributeConstraintsRule)
            const nesting = {depth: 0, offset: {start: 0, end: 0}, position: {start: {line: 0, column: 0}, end: {line: 0, column: 0}}} // unused placeholder
            return removeUndefined({nesting, name, type, enumValues, defaultValue, nullable: nullable ? tokenInfo(nullable) : undefined, ...constraints})
        }, {resyncEnabled: true})
        this.attributeRule = $.RULE<() => AttributeAstFlat>('attributeRule', () => {
            const spaces = $.CONSUME(WhiteSpace)
            const depth = Math.round(spaces.image.split('').reduce((i, c) => c === '\t' ? i + 1 : i + 0.5, 0)) - 1
            const nesting = {...tokenInfo(spaces), depth}
            const attr = $.SUBRULE(attributeRuleInner)
            $.OPTION(() => $.CONSUME2(WhiteSpace))
            const relation = $.OPTION3(() => $.SUBRULE(attributeRelationRule))
            $.OPTION4(() => $.CONSUME3(WhiteSpace))
            const extra = $.SUBRULE($.extraRule)
            $.CONSUME(NewLine)
            return removeUndefined({...attr, nesting, relation, ...extra})
        })

        this.entityRule = $.RULE<() => EntityStatement>('entityRule', () => {
            const {entity, ...namespace} = $.SUBRULE($.entityRefRule)
            const view = $.OPTION(() => $.CONSUME(Asterisk))
            $.OPTION2(() => $.CONSUME(WhiteSpace))
            const alias = $.OPTION3(() => {
                $.CONSUME(As)
                $.CONSUME2(WhiteSpace)
                return $.SUBRULE($.identifierRule)
            })
            $.OPTION4(() => $.CONSUME3(WhiteSpace))
            const extra = $.SUBRULE($.extraRule)
            $.CONSUME(NewLine)
            const attrs: AttributeAstFlat[] = []
            $.MANY(() => attrs.push($.SUBRULE($.attributeRule)))
            return removeEmpty({statement: 'Entity' as const, name: entity, view: view ? tokenInfo(view) : undefined, ...namespace, alias, ...extra, attrs: nestAttributes(attrs)})
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
            const attr = $.SUBRULE($.attributePathRule)
            $.CONSUME(Equal)
            const value = $.SUBRULE($.attributeValueRule)
            return {attr, value}
        })
        this.relationRule = $.RULE<() => RelationStatement>('relationRule', () => {
            const warning = $.OR([
                {ALT: () => {$.CONSUME(Relation); return undefined}},
                {ALT: () => tokenInfoLegacy($.CONSUME(ForeignKey), '"fk" is legacy, replace it with "rel"')}
            ])
            $.CONSUME(WhiteSpace)
            const src = $.SUBRULE($.attributeRefCompositeRule)
            $.OPTION(() => $.CONSUME2(WhiteSpace))
            const {kind, ref, polymorphic} = $.SUBRULE(attributeRelationRule) || {} // returns undefined on invalid input :/
            $.OPTION2(() => $.CONSUME3(WhiteSpace))
            const extra = $.SUBRULE($.extraRule)
            $.CONSUME(NewLine)
            return removeUndefined({statement: 'Relation' as const, kind, src, ref, polymorphic, ...extra, warning})
        })

        // type rules
        const typeAliasRule = $.RULE<() => TypeAliasAst>('typeAliasRule', () => {
            return { kind: 'alias', name: $.SUBRULE($.identifierRule) }
        })
        const typeEnumRule = $.RULE<() => TypeEnumAst>('typeEnumRule', () => {
            $.CONSUME(LParen)
            const values: AttributeValueAst[] = []
            $.MANY_SEP({
                SEP: Comma,
                DEF: () => {
                    $.OPTION(() => $.CONSUME(WhiteSpace))
                    values.push($.SUBRULE($.attributeValueRule))
                    $.OPTION2(() => $.CONSUME2(WhiteSpace))
                }
            })
            $.CONSUME(RParen)
            return { kind: 'enum', values }
        })
        const typeStructRule = $.RULE<() => TypeStructAst>('typeStructRule', () => {
            $.CONSUME(LCurly)
            const attrs: AttributeAstFlat[] = []
            $.MANY_SEP({
                SEP: Comma,
                DEF: () => {
                    $.OPTION(() => $.CONSUME(WhiteSpace))
                    attrs.push($.SUBRULE(attributeRuleInner))
                    $.OPTION2(() => $.CONSUME2(WhiteSpace))
                }
            })
            $.CONSUME(RCurly)
            return { kind: 'struct', attrs: nestAttributes(attrs) }
        })
        const typeCustomRule = $.RULE<() => TypeCustomAst>('typeCustomRule', () => {
            const definition = $.SUBRULE($.expressionRule)
            return { kind: 'custom', definition }
        })
        this.typeRule = $.RULE<() => TypeStatement>('typeRule', () => {
            $.CONSUME(Type)
            $.CONSUME(WhiteSpace)
            const {entity, ...namespace} = $.SUBRULE(this.entityRefRule) || {} // returns undefined on invalid input :/
            $.OPTION(() => $.CONSUME2(WhiteSpace))
            let content = $.OPTION2(() => $.OR([
                { ALT: () => $.SUBRULE(typeEnumRule) },
                { ALT: () => $.SUBRULE(typeStructRule) },
                { ALT: () => $.SUBRULE(typeCustomRule) },
                { ALT: () => $.SUBRULE(typeAliasRule) },
            ]))
            $.OPTION3(() => $.CONSUME3(WhiteSpace))
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
        this.emptyStatementRule = $.RULE<() => EmptyStatement>('emptyStatementRule', () => {
            $.OPTION(() => $.CONSUME(WhiteSpace))
            const comment = $.OPTION2(() => $.SUBRULE($.commentRule))
            $.CONSUME(NewLine)
            return removeUndefined({statement: 'Empty' as const, comment})
        })

        // general rules
        this.statementRule = $.RULE<() => StatementAst>('statementRule', () => {
            return $.OR([
                { ALT: () => $.SUBRULE($.namespaceRule) },
                { ALT: () => $.SUBRULE($.entityRule) },
                { ALT: () => $.SUBRULE($.relationRule) },
                { ALT: () => $.SUBRULE($.typeRule) },
                { ALT: () => $.SUBRULE($.emptyStatementRule) },
            ])
        })

        this.amlRule = $.RULE<() => AmlAst>('amlRule', () => {
            let stmts: StatementAst[] = []
            $.MANY(() => stmts.push($.SUBRULE($.statementRule)))
            return stmts
        })

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

export function parseAmlAst(input: string, opts: { strict: boolean }): ParserResult<AmlAst> {
    return parseRule(p => p.amlRule(), input, opts.strict)
}

function formatLexerError(err: ILexingError): ParserError {
    return {
        name: 'LexingError',
        kind: 'error',
        message: err.message,
        offset: {start: err.offset, end: err.offset + err.length},
        position: {
            start: {line: err.line || defaultPos, column: err.column || defaultPos},
            end: {line: err.line || defaultPos, column: (err.column || defaultPos) + err.length}
        }
    }
}

function formatParserError(err: IRecognitionException): ParserError {
    return {name: err.name, kind: 'error', message: err.message, ...tokenInfo(err.token)}
}

function tokenInfo(token: IToken, issues?: TokenIssue[]): TokenInfo {
    return removeEmpty({...tokenPosition(token), issues})
}

function tokenInfoLegacy(token: IToken, message: string): TokenInfo {
    return tokenInfo(token, [legacy(message)])
}

function tokenPosition(token: IToken): TokenPosition {
    return {
        offset: {start: token.startOffset, end: token.endOffset || defaultPos},
        position: {
            start: {line: token.startLine || defaultPos, column: token.startColumn || defaultPos},
            end: {line: token.endLine || defaultPos, column: token.endColumn || defaultPos}
        }
    }
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
