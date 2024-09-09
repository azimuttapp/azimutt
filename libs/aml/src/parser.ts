import {
    createToken,
    EmbeddedActionsParser,
    ILexingError,
    IRecognitionException,
    IToken,
    Lexer,
    TokenType
} from "chevrotain";
import {isObject, removeEmpty, removeUndefined, stripIndent} from "@azimutt/utils";
import {
    isParserErrorKind,
    isTokenPosition,
    ParserError,
    ParserErrorKind,
    ParserResult,
    TokenPosition
} from "@azimutt/models";

// special
const WhiteSpace = createToken({name: 'WhiteSpace', pattern: /[ \t]+/})
const Identifier = createToken({ name: 'Identifier', pattern: /[a-zA-Z_][a-zA-Z0-9_#]*|"([^\\"]|\\\\|\\")*"/ })
const Expression = createToken({ name: 'Expression', pattern: /`[^`]+`/ })
const Doc = createToken({ name: 'Doc', pattern: /\|[^#\n]*/ })
const DocMultiline = createToken({ name: 'DocMultiline', pattern: /\|\|\|[^]*?\|\|\|/, line_breaks: true })
const Comment = createToken({ name: 'Comment', pattern: /#[^\n]*/ })

// values
const Null = createToken({ name: 'Null', pattern: /null/ })
const Decimal = createToken({ name: 'Decimal', pattern: /\d+\.\d+/ })
const Integer = createToken({ name: 'Integer', pattern: /\d+/, longer_alt: Decimal })
const String = createToken({ name: 'String', pattern: /'([^\\']|\\\\|\\')*'/ })
const Boolean = createToken({ name: 'Boolean', pattern: /true|false/, longer_alt: Identifier })
const valueTokens: TokenType[] = [Integer, Decimal, String, Boolean, Null]

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
const LCurly = createToken({ name: 'LCurly', pattern: /\{/ })
const RCurly = createToken({ name: 'RCurly', pattern: /}/ })
const charTokens: TokenType[] = [Asterisk, Dot, Comma, Colon, Equal, Dash, GreaterThan, LowerThan, LParen, RParen, LCurly, RCurly]

// legacy tokens
const ForeignKey = createToken({ name: 'ForeignKey', pattern: /fk/ })
const legacyTokens: TokenType[] = [ForeignKey]

// token order is important as they are tried in order, so the Identifier must be last
const allTokens: TokenType[] = [WhiteSpace, NewLine, ...charTokens, ...keywordTokens, ...legacyTokens, ...valueTokens, Expression, Identifier, DocMultiline, Doc, Comment]

export type AmlAst = StatementAst[]
export type StatementAst = NamespaceAst | EntityAst | RelationAst | TypeAst | EmptyStatementAst
export type NamespaceAst = { statement: 'Namespace', schema: IdentifierToken, catalog?: IdentifierToken, database?: IdentifierToken } & ExtraAst
export type EntityAst = { statement: 'Entity', name: IdentifierToken, view?: TokenInfo, alias?: IdentifierToken, attrs?: AttributeAstNested[] } & NamespaceRefAst & ExtraAst
export type RelationAst = { statement: 'Relation', kind: RelationKindAst, src: AttributeRefCompositeAst, ref: AttributeRefCompositeAst, polymorphic?: RelationPolymorphicAst } & ExtraAst
export type TypeAst = { statement: 'Type', name: IdentifierToken, content?: TypeContentAst } & NamespaceRefAst & ExtraAst
export type EmptyStatementAst = { statement: 'Empty', comment?: CommentToken }

export type AttributeAstFlat = { nesting: number, name: IdentifierToken, nullable?: TokenInfo } & AttributeTypeAst & AttributeConstraintsAst & { relation?: AttributeRelationAst } & ExtraAst
export type AttributeAstNested = { path: IdentifierToken[], nullable?: TokenInfo } & AttributeTypeAst & AttributeConstraintsAst & { relation?: AttributeRelationAst } & ExtraAst & { attrs?: AttributeAstNested[] }
export type AttributeTypeAst = { type?: IdentifierToken, enumValues?: AttributeValueAst[], defaultValue?: AttributeValueAst }
export type AttributeConstraintsAst = { primaryKey?: AttributeConstraintAst, index?: AttributeConstraintAst, unique?: AttributeConstraintAst, check?: AttributeCheckAst }
export type AttributeConstraintAst = { keyword: TokenInfo, name?: IdentifierToken }
export type AttributeCheckAst = { keyword: TokenInfo, definition?: ExpressionToken }
export type AttributeRelationAst = { kind: RelationKindAst, ref: AttributeRefCompositeAst, polymorphic?: RelationPolymorphicAst, warning?: TokenInfo }

export type RelationCardinalityAst = '1' | 'n'
export type RelationKindAst = `${RelationCardinalityAst}-${RelationCardinalityAst}`
export type RelationPolymorphicAst = { attr: AttributePathAst, value: AttributeValueAst }

export type TypeContentAst = TypeAliasAst | TypeEnumAst | TypeStructAst | TypeCustomAst
export type TypeAliasAst = { kind: 'alias', name: IdentifierToken }
export type TypeEnumAst = { kind: 'enum', values: AttributeValueAst[] }
export type TypeStructAst = { kind: 'struct', attrs: AttributeAstNested[] }
export type TypeCustomAst = { kind: 'custom', definition: ExpressionToken }

export type NamespaceRefAst = { schema?: IdentifierToken, catalog?: IdentifierToken, database?: IdentifierToken }
export type EntityRefAst = { entity: IdentifierToken } & NamespaceRefAst
export type AttributePathAst = IdentifierToken & { path?: IdentifierToken[] }
export type AttributeRefAst = EntityRefAst & { attr: AttributePathAst }
export type AttributeRefCompositeAst = EntityRefAst & { attrs: AttributePathAst[] }
export type AttributeValueAst = NullToken | DecimalToken | IntegerToken | BooleanToken | ExpressionToken | IdentifierToken // TODO: add date

export type ExtraAst = { properties?: PropertiesAst, doc?: DocToken, comment?: CommentToken }
export type PropertiesAst = PropertyAst[]
export type PropertyAst = { key: IdentifierToken, value?: PropertyValueAst }
export type PropertyValueAst = NullToken | DecimalToken | IntegerToken | BooleanToken | ExpressionToken | IdentifierToken

// basic tokens
export type NullToken = { token: 'Null' } & TokenInfo
export type DecimalToken = { token: 'Decimal', value: number } & TokenInfo
export type IntegerToken = { token: 'Integer', value: number } & TokenInfo
export type BooleanToken = { token: 'Boolean', value: boolean } & TokenInfo
export type ExpressionToken = { token: 'Expression', value: string } & TokenInfo
export type IdentifierToken = { token: 'Identifier', value: string } & TokenInfo
export type DocToken = { token: 'Doc', value: string } & TokenPosition
export type CommentToken = { token: 'Comment', value: string } & TokenPosition

export type TokenInfo = TokenPosition & { issues?: TokenIssue[] }
export type TokenIssue = { name: string, kind: ParserErrorKind, message: string }

export const isTokenInfo = (value: unknown): value is TokenInfo => isTokenPosition(value) && (!('issues' in value) || ('issues' in value && Array.isArray(value.issues) && value.issues.every(isTokenIssue)))
export const isTokenIssue = (value: unknown): value is TokenIssue => isObject(value) && ('kind' in value && isParserErrorKind(value.kind)) && ('message' in value && typeof value.message === 'string')

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
    namespaceRule: () => NamespaceAst

    // entity
    attributeRule: () => AttributeAstFlat
    entityRule: () => EntityAst

    // relation
    relationRule: () => RelationAst

    // type
    typeRule: () => TypeAst

    // general
    emptyStatementRule: () => EmptyStatementAst
    statementRule: () => StatementAst
    amlRule: () => AmlAst

    constructor(tokens: TokenType[]) {
        super(tokens, {recoveryEnabled: true})
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
                    return {token: 'Doc', value: token.image.slice(1).trim(), ...tokenPosition(token)}
                }
            }])
        })

        this.commentRule = $.RULE<() => CommentToken>('commentRule', () => {
            const token = $.CONSUME(Comment)
            return {token: 'Comment', value: token.image.slice(1).trim(), ...tokenPosition(token)}
        })

        const propertyValueRule = $.RULE<() => PropertyValueAst>('propertyValueRule', () => {
            // TODO: be more flexible: string value: anything without ',' + add business rules for tags for example (split values?)
            return $.OR([
                { ALT: () => $.SUBRULE($.nullRule) },
                { ALT: () => $.SUBRULE($.decimalRule) },
                { ALT: () => $.SUBRULE($.integerRule) },
                { ALT: () => $.SUBRULE($.booleanRule) },
                { ALT: () => $.SUBRULE($.expressionRule) },
                { ALT: () => $.SUBRULE($.identifierRule) },
            ])
        })
        const propertyRule = $.RULE<() => PropertyAst>('propertyRule', () => {
            const key = $.SUBRULE($.identifierRule)
            $.OPTION(() => $.CONSUME(WhiteSpace))
            const value = $.OPTION2(() => {
                $.OR([
                    {ALT: () => $.CONSUME(Colon) },
                    {ALT: () => $.CONSUME(Equal) }, // TODO: legacy rule
                ])
                $.OPTION3(() => $.CONSUME2(WhiteSpace))
                return $.SUBRULE(propertyValueRule)
            })
            return {key, value}
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
                    const path = $.SUBRULE(legacyAttributePathRule)
                    return removeUndefined({schema: entity.catalog, entity: entity.schema, attr: removeEmpty({...entity.entity, path})}) // TODO: add warning in AST
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
                    // don't work :/ it try to consume even with schema :/
                    // if (!entity.schema) { $.CONSUME(Dot) } // make the rule fail as it should have at least a `schema.entity` to be used as `entity.attr`
                    const path = $.SUBRULE(legacyAttributePathRule)
                    return removeUndefined({schema: entity.catalog, entity: entity.schema, attrs: [removeEmpty({...entity.entity, path})]}) // TODO: add warning in AST
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
        this.namespaceRule = $.RULE<() => NamespaceAst>('namespaceRule', () => {
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
                            values.push($.SUBRULE($.attributeValueRule)) // TODO: retro-compatibility: allow any char between ',' (ex: '(16:9, 1:1)')
                            $.OPTION4(() => $.CONSUME2(WhiteSpace))
                        }
                    })
                    $.CONSUME(RParen)
                    return values
                })
                const defaultValue = $.OPTION5(() => {
                    $.CONSUME(Equal)
                    return $.SUBRULE2($.attributeValueRule) // TODO: retro-compatibility: allow expression without backticks (ex: 'timestamp=now()')
                })
                return {type, enumValues, defaultValue}
            })
            return {type: res?.type, enumValues: res?.enumValues, defaultValue: res?.defaultValue}
        })
        const attributeConstraintPkRule = $.RULE<() => AttributeConstraintAst>('attributeConstraintPkRule', () => {
            const token = $.CONSUME(PrimaryKey)
            const name = $.OPTION(() => {
                $.CONSUME(Equal)
                return $.SUBRULE($.identifierRule)
            })
            return removeUndefined({keyword: tokenInfo(token), name})
        })
        const attributeConstraintIndexRule = $.RULE<() => AttributeConstraintAst>('attributeConstraintIndexRule', () => {
            const token = $.CONSUME(Index)
            const name = $.OPTION(() => {
                $.CONSUME(Equal)
                return $.SUBRULE($.identifierRule)
            })
            return removeUndefined({keyword: tokenInfo(token), name})
        })
        const attributeConstraintUniqueRule = $.RULE<() => AttributeConstraintAst>('attributeConstraintUniqueRule', () => {
            const token = $.CONSUME(Unique)
            const name = $.OPTION(() => {
                $.CONSUME(Equal)
                return $.SUBRULE($.identifierRule)
            })
            return removeUndefined({keyword: tokenInfo(token), name})
        })
        const attributeConstraintCheckRule = $.RULE<() => AttributeCheckAst>('attributeConstraintCheckRule', () => {
            const token = $.CONSUME(Check)
            const definition = $.OPTION(() => {
                $.CONSUME(Equal)
                return $.SUBRULE($.expressionRule) // TODO: retro-compatibility: allow expression with double quotes instead of backticks (ex: 'check="age > 0"')
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
                    const token = $.CONSUME(ForeignKey)
                    const warning = tokenInfo(token, [{name: 'LegacyWarning', kind: 'warning', message: '"fk" is legacy, replace it with "->"'}])
                    return {kind: 'n-1', polymorphic: undefined, warning} // TODO: add warning in AST
                }
            }])
            $.OPTION2(() => $.CONSUME(WhiteSpace))
            const ref = $.SUBRULE2($.attributeRefCompositeRule)
            return removeUndefined({kind, ref, polymorphic, warning})
        })
        const attributeRuleInner = $.RULE<() => AttributeAstFlat>('attributeRuleInner', () => {
            const name = $.SUBRULE($.identifierRule)
            $.OPTION(() => $.CONSUME2(WhiteSpace))
            const {type, enumValues, defaultValue} = $.SUBRULE(attributeTypeRule)
            $.OPTION2(() => $.CONSUME3(WhiteSpace))
            const nullable = $.OPTION3(() => $.CONSUME(Nullable))
            $.OPTION4(() => $.CONSUME4(WhiteSpace))
            const constraints = $.SUBRULE(attributeConstraintsRule)
            return removeUndefined({nesting: 0, name, type, enumValues, defaultValue, nullable: nullable ? tokenInfo(nullable) : undefined, ...constraints})
        }, {resyncEnabled: true})
        this.attributeRule = $.RULE<() => AttributeAstFlat>('attributeRule', () => {
            const spaces = $.CONSUME(WhiteSpace)
            const nesting = Math.round(spaces.image.split('').reduce((i, c) => c === '\t' ? i + 1 : i + 0.5, 0)) - 1
            const attr = $.SUBRULE(attributeRuleInner)
            $.OPTION(() => $.CONSUME2(WhiteSpace))
            const relation = $.OPTION3(() => $.SUBRULE(attributeRelationRule))
            $.OPTION4(() => $.CONSUME3(WhiteSpace))
            const extra = $.SUBRULE($.extraRule)
            $.CONSUME(NewLine)
            return removeUndefined({...attr, nesting, relation, ...extra})
        })

        this.entityRule = $.RULE<() => EntityAst>('entityRule', () => {
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
        this.relationRule = $.RULE<() => RelationAst>('relationRule', () => {
            $.OR([
                { ALT: () => $.CONSUME(Relation) },
                { ALT: () => $.CONSUME(ForeignKey) }, // TODO: add warning in AST
            ])
            $.CONSUME(WhiteSpace)
            const src = $.SUBRULE($.attributeRefCompositeRule)
            $.OPTION(() => $.CONSUME2(WhiteSpace))
            const {kind, ref, polymorphic} = $.SUBRULE(attributeRelationRule) || {} // returns undefined on invalid input :/
            $.OPTION2(() => $.CONSUME3(WhiteSpace))
            const extra = $.SUBRULE($.extraRule)
            $.CONSUME(NewLine)
            return removeUndefined({statement: 'Relation' as const, kind, src, ref, polymorphic, ...extra})
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
        this.typeRule = $.RULE<() => TypeAst>('typeRule', () => {
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
        this.emptyStatementRule = $.RULE<() => EmptyStatementAst>('emptyStatementRule', () => {
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
const parser = new AmlParser(allTokens)

// exported only for tests, use the `parse` function instead
export function parseRule<T>(parse: (p: AmlParser) => T, input: string): ParserResult<T> {
    const lexingResult = lexer.tokenize(input)
    parser.input = lexingResult.tokens // "input" is a setter which will reset the parser's state.
    const res = parse(parser)
    const errors = lexingResult.errors.map(formatLexerError).concat(parser.errors.map(formatParserError))
    return new ParserResult(res, errors)
}

export function parseAmlAst(input: string): ParserResult<AmlAst> {
    return parseRule(p => p.amlRule(), input)
}

function formatLexerError(err: ILexingError): ParserError {
    return {
        name: 'LexingError',
        kind: 'error',
        message: err.message,
        offset: {start: err.offset, end: err.offset + err.length},
        position: {
            start: {line: err.line || 0, column: err.column || 0},
            end: {line: err.line || 0, column: (err.column || 0) + err.length}
        }
    }
}

function formatParserError(err: IRecognitionException): ParserError {
    return {name: err.name, kind: 'error', message: err.message, ...tokenInfo(err.token)}
}

function tokenInfo(token: IToken, issues?: TokenIssue[]): TokenInfo {
    return removeEmpty({...tokenPosition(token), issues})
}

function tokenPosition(token: IToken): TokenPosition {
    return {
        offset: {start: token.startOffset, end: token.endOffset || 0},
        position: {
            start: {line: token.startLine || 0, column: token.startColumn || 0},
            end: {line: token.endLine || 0, column: token.endColumn || 0}
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
        const {nesting, name, ...values} = attribute
        if (nesting === 0 || parents.length === 0) { // empty parents is when first attr is not at nesting 0
            path = [name]
            parents = [{path, ...values}]
            curNesting = 0
            results.push(parents[0]) // add top level attrs to results
        } else if (nesting > curNesting) { // deeper: append to `path` & `parents`
            path = [...path, name]
            parents = [...parents, {path, ...values}]
            curNesting = curNesting + 1 // go only one level deeper at the time (even if nesting is higher)
            // if (nesting > curNesting + 1) console.log(`bad nesting (+${nesting - curNesting}) on attr ${JSON.stringify(attribute)}`) // TODO: add warning in ast
            parents[parents.length - 2].attrs = [...(parents[parents.length - 2].attrs || []), parents[parents.length - 1]] // add to parent
        } else if (nesting <= curNesting) { // same level or up: replace n+1 last values in `path` & `parents`
            const n = curNesting - nesting
            path = [...path.slice(0, -(n + 1)), name]
            parents = [...parents.slice(0, -(n + 1)), {path, ...values}]
            curNesting = nesting
            parents[parents.length - 2].attrs = [...(parents[parents.length - 2].attrs || []), parents[parents.length - 1]] // add to parent
        } else { // should never happen, `nesting` is always > or <= to `curNesting`
            throw new Error(`Should never happen (nesting: ${nesting}, curNesting: ${curNesting})`)
        }
    })
    return results
}
