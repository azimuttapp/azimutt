import {createToken, EmbeddedActionsParser, IRecognitionException, IToken, Lexer, TokenType} from "chevrotain";
import {removeEmpty, removeUndefined, stripIndent} from "@azimutt/utils";
import {ParserError, ParserPosition, ParserResult} from "@azimutt/models";

// special
const WhiteSpace = createToken({name: 'WhiteSpace', pattern: /[ \t]+/})
const Identifier = createToken({ name: 'Identifier', pattern: /[a-zA-Z_]\w*|"([^\\"]|\\\\|\\")*"/ })
const Expression = createToken({ name: 'Expression', pattern: /`[^`]+`/ })
const Note = createToken({ name: 'Note', pattern: /\|[^#\n]*/ })
const NoteMultiline = createToken({ name: 'NoteMultiline', pattern: /\|\|\|[^]*?\|\|\|/, line_breaks: true })
const Comment = createToken({ name: 'Comment', pattern: /#[^\n]*/ })

// values
const Null = createToken({ name: 'Null', pattern: /null/ })
const Float = createToken({ name: 'Float', pattern: /\d+\.\d+/ })
const Integer = createToken({ name: 'Integer', pattern: /\d+/, longer_alt: Float })
const String = createToken({ name: 'String', pattern: /'([^\\']|\\\\|\\')*'/ })
const Boolean = createToken({ name: 'Boolean', pattern: /true|false/, longer_alt: Identifier })
const valueTokens: TokenType[] = [Integer, Float, String, Boolean, Null]

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
const charTokens: TokenType[] = [Dot, Comma, Colon, Equal, Dash, GreaterThan, LowerThan, LParen, RParen, LCurly, RCurly]

// legacy tokens
const ForeignKey = createToken({ name: 'ForeignKey', pattern: /fk/ })
const legacyTokens: TokenType[] = [ForeignKey]

// token order is important as they are tried in order, so the Identifier must be last
const allTokens: TokenType[] = [WhiteSpace, NewLine, ...charTokens, ...keywordTokens, ...legacyTokens, ...valueTokens, Expression, Identifier, NoteMultiline, Note, Comment]

export type AmlAst = StatementAst[]
export type StatementAst = NamespaceAst | EntityAst | RelationAst | TypeAst | EmptyStatementAst
export type NamespaceAst = { statement: 'Namespace', schema: IdentifierAst, catalog?: IdentifierAst, database?: IdentifierAst } & ExtraAst
export type EntityAst = { statement: 'Entity', name: IdentifierAst, alias?: IdentifierAst, attrs: AttributeAstNested[] } & NamespaceRefAst & ExtraAst
export type RelationAst = { statement: 'Relation', kind: RelationKindAst, src: AttributeRefCompositeAst, ref: AttributeRefCompositeAst, polymorphic?: RelationPolymorphicAst } & ExtraAst
export type TypeAst = { statement: 'Type', name: IdentifierAst, content?: TypeContentAst } & NamespaceRefAst & ExtraAst
export type EmptyStatementAst = { statement: 'Empty', comment?: CommentAst }

export type AttributeAstFlat = { nesting: number, name: IdentifierAst, nullable?: {parser: TokenInfo} } & AttributeTypeAst & AttributeConstraintsAst & { relation?: AttributeRelationAst } & ExtraAst
export type AttributeAstNested = { path: IdentifierAst[], nullable?: {parser: TokenInfo} } & AttributeTypeAst & AttributeConstraintsAst & { relation?: AttributeRelationAst } & ExtraAst & { attrs?: AttributeAstNested[] }
export type AttributeTypeAst = { type?: IdentifierAst, enumValues?: AttributeValueAst[], defaultValue?: AttributeValueAst }
export type AttributeConstraintsAst = { primaryKey?: AttributeConstraintAst, index?: AttributeConstraintAst, unique?: AttributeConstraintAst, check?: AttributeCheckAst }
export type AttributeConstraintAst = { parser: TokenInfo, value?: IdentifierAst }
export type AttributeCheckAst = { parser: TokenInfo, value?: ExpressionAst }
export type AttributeRelationAst = { kind: RelationKindAst, ref: AttributeRefCompositeAst, polymorphic?: RelationPolymorphicAst }

export type RelationCardinalityAst = '1' | 'n'
export type RelationKindAst = `${RelationCardinalityAst}-${RelationCardinalityAst}`
export type RelationPolymorphicAst = { attr: AttributePathAst, value: AttributeValueAst }

export type TypeContentAst = TypeAliasAst | TypeEnumAst | TypeStructAst | TypeCustomAst
export type TypeAliasAst = { kind: 'alias', name: IdentifierAst }
export type TypeEnumAst = { kind: 'enum', values: AttributeValueAst[] }
export type TypeStructAst = { kind: 'struct', attrs: AttributeAstNested[] }
export type TypeCustomAst = { kind: 'custom', definition: ExpressionAst }

export type NamespaceRefAst = { schema?: IdentifierAst, catalog?: IdentifierAst, database?: IdentifierAst }
export type EntityRefAst = { entity: IdentifierAst } & NamespaceRefAst
export type AttributePathAst = IdentifierAst & { path?: IdentifierAst[] }
export type AttributeRefAst = EntityRefAst & { attr: AttributePathAst }
export type AttributeRefCompositeAst = EntityRefAst & { attrs: AttributePathAst[] }
export type AttributeValueAst = NullAst | NumberAst | BooleanAst | ExpressionAst | IdentifierAst // TODO: add date

export type ExtraAst = { properties?: PropertiesAst, note?: NoteAst, comment?: CommentAst }
export type PropertiesAst = PropertyAst[]
export type PropertyAst = { key: IdentifierAst, value?: PropertyValueAst }
export type PropertyValueAst = NullAst | NumberAst | BooleanAst | ExpressionAst | IdentifierAst
export type NoteAst = { note: string, parser: TokenInfo }
export type CommentAst = { comment: string, parser: TokenInfo }
export type NullAst = { null: true, parser: TokenInfo }
export type NumberAst = { value: number, parser: TokenInfo }
export type BooleanAst = { flag: boolean, parser: TokenInfo }
export type IdentifierAst = { identifier: string, parser: TokenInfo }
export type ExpressionAst = { expression: string, parser: TokenInfo }

export type TokenInfo = {token: string, offset: ParserPosition, line: ParserPosition, column: ParserPosition}

class AmlParser extends EmbeddedActionsParser {
    // common
    nullRule: () => NullAst
    numberRule: () => NumberAst
    booleanRule: () => BooleanAst
    expressionRule: () => ExpressionAst
    identifierRule: () => IdentifierAst
    commentRule: () => CommentAst
    noteRule: () => NoteAst
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
        super(tokens)
        const $ = this

        // common rules
        this.nullRule = $.RULE<() => NullAst>('nullRule', () => {
            const token = $.CONSUME(Null)
            return {null: true, parser: parserInfo(token)}
        })

        this.numberRule = $.RULE<() => NumberAst>('numberRule', () => {
            return $.OR([
                { ALT: () => {
                    const token = $.CONSUME(Float)
                    return {value: parseFloat(token.image), parser: parserInfo(token)}
                }},
                { ALT: () => {
                    const token = $.CONSUME(Integer)
                    return {value: parseInt(token.image), parser: parserInfo(token)}
                }},
            ])
        })

        this.booleanRule = $.RULE<() => BooleanAst>('booleanRule', () => {
            const token = $.CONSUME(Boolean)
            return {flag: token.image.toLowerCase() === 'true', parser: parserInfo(token)}
        })

        this.expressionRule = $.RULE<() => ExpressionAst>('expressionRule', () => {
            const token = $.CONSUME(Expression)
            return {expression: token.image.slice(1, -1), parser: parserInfo(token)}
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
            return $.OR([{
                ALT: () => {
                    const token = $.CONSUME(NoteMultiline)
                    return {note: stripIndent(token.image.slice(3, -3)), parser: parserInfo(token)}
                }
            }, {
                ALT: () => {
                    const token = $.CONSUME(Note)
                    return {note: token.image.slice(1).trim(), parser: parserInfo(token)}
                }
            }])
        })

        const propertyValueRule = $.RULE<() => PropertyValueAst>('propertyValueRule', () => {
            // TODO: be more flexible: string value: anything without ',' + add business rules for tags for example (split values?)
            return $.OR([
                { ALT: () => $.SUBRULE($.nullRule) },
                { ALT: () => $.SUBRULE($.numberRule) },
                { ALT: () => $.SUBRULE($.booleanRule) },
                { ALT: () => $.SUBRULE($.expressionRule) },
                { ALT: () => $.SUBRULE($.identifierRule) },
            ])
        })
        const propertyRule = $.RULE<() => PropertyAst>('propertyRule', () => {
            const key = $.SUBRULE($.identifierRule)
            $.OPTION(() => $.CONSUME(WhiteSpace))
            const value = $.OPTION2(() => {
                $.CONSUME(Colon)
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
            const note = $.OPTION3(() => $.SUBRULE2($.noteRule))
            $.OPTION4(() => $.CONSUME2(WhiteSpace))
            const comment = $.OPTION5(() => $.SUBRULE3($.commentRule))
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

        this.attributePathRule = $.RULE<() => AttributePathAst>('attributePathRule', () => {
            const attr = $.SUBRULE($.identifierRule)
            const path: IdentifierAst[] = []
            $.MANY(() => path.push($.SUBRULE(nestedRule)))
            return removeEmpty({...attr, path})
        })

        const legacyAttributePathRule = $.RULE<() => IdentifierAst[]>('legacyAttributePathRule', () => {
            const path: IdentifierAst[] = []
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
                ALT: () => {
                    // legacy fallback
                    const path = $.SUBRULE(legacyAttributePathRule)
                    return removeUndefined({schema: entity.catalog, entity: entity.schema, attrs: [removeEmpty({...entity.entity, path})]}) // TODO: add warning in AST
                }
            }])
        })

        this.attributeValueRule = $.RULE<() => AttributeValueAst>('attributeValueRule', () => {
            return $.OR([
                { ALT: () => $.SUBRULE($.nullRule) },
                { ALT: () => $.SUBRULE($.numberRule) },
                { ALT: () => $.SUBRULE($.booleanRule) },
                { ALT: () => $.SUBRULE($.expressionRule) },
                { ALT: () => $.SUBRULE($.identifierRule) },
            ])
        })

        // namespace rules
        this.namespaceRule = $.RULE<() => NamespaceAst>('namespaceRule', () => {
            $.CONSUME(Namespace)
            $.CONSUME(WhiteSpace)
            // TODO: retro-compatibility: allow more chars inside identifiers (ex: 'C##INVENTORY')
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
            const value = $.OPTION(() => {
                $.CONSUME(Equal)
                return $.SUBRULE($.identifierRule)
            })
            return removeUndefined({parser: parserInfo(token), value})
        })
        const attributeConstraintIndexRule = $.RULE<() => AttributeConstraintAst>('attributeConstraintIndexRule', () => {
            const token = $.CONSUME(Index)
            const value = $.OPTION(() => {
                $.CONSUME(Equal)
                return $.SUBRULE($.identifierRule)
            })
            return removeUndefined({parser: parserInfo(token), value})
        })
        const attributeConstraintUniqueRule = $.RULE<() => AttributeConstraintAst>('attributeConstraintUniqueRule', () => {
            const token = $.CONSUME(Unique)
            const value = $.OPTION(() => {
                $.CONSUME(Equal)
                return $.SUBRULE($.identifierRule)
            })
            return removeUndefined({parser: parserInfo(token), value})
        })
        const attributeConstraintCheckRule = $.RULE<() => AttributeCheckAst>('attributeConstraintCheckRule', () => {
            const token = $.CONSUME(Check)
            const value = $.OPTION(() => {
                $.CONSUME(Equal)
                return $.SUBRULE($.expressionRule) // TODO: retro-compatibility: allow expression with double quotes instead of backticks (ex: 'check="age > 0"')
            })
            return removeUndefined({parser: parserInfo(token), value})
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
            const {kind, polymorphic} = $.OR([{
                ALT: () => {
                    const refCardinality = $.SUBRULE(relationCardinalityRule)
                    const polymorphic = $.OPTION(() => $.SUBRULE(relationPolymorphicRule))
                    const srcCardinality = $.SUBRULE2(relationCardinalityRule)
                    return {kind: `${srcCardinality}-${refCardinality}` as const, polymorphic}
                }
            }, {
                ALT: () => {
                    $.CONSUME(ForeignKey)
                    return {kind: 'n-1', polymorphic: undefined} // TODO: add warning in AST
                }
            }])
            $.OPTION2(() => $.CONSUME(WhiteSpace))
            const ref = $.SUBRULE2($.attributeRefCompositeRule)
            return removeUndefined({kind, ref, polymorphic})
        })
        const attributeRuleInner = $.RULE<() => AttributeAstFlat>('attributeRuleInner', () => {
            const name = $.SUBRULE($.identifierRule)
            $.OPTION(() => $.CONSUME2(WhiteSpace))
            const {type, enumValues, defaultValue} = $.SUBRULE(attributeTypeRule)
            $.OPTION2(() => $.CONSUME3(WhiteSpace))
            const isNull = $.OPTION3(() => $.CONSUME(Nullable))
            const nullable = isNull ? {parser: parserInfo(isNull)} : undefined
            $.OPTION4(() => $.CONSUME4(WhiteSpace))
            const constraints = $.SUBRULE(attributeConstraintsRule)
            $.OPTION5(() => $.CONSUME5(WhiteSpace))
            const relation = $.OPTION6(() => $.SUBRULE(attributeRelationRule))
            return removeUndefined({nesting: 0, name, type, enumValues, defaultValue, nullable, ...constraints, relation})
        })
        this.attributeRule = $.RULE<() => AttributeAstFlat>('attributeRule', () => {
            const spaces = $.CONSUME(WhiteSpace)
            const nesting = Math.round(spaces.image.split('').reduce((i, c) => c === '\t' ? i + 1 : i + 0.5, 0)) - 1
            const attr = $.SUBRULE(attributeRuleInner)
            $.OPTION(() => $.CONSUME2(WhiteSpace))
            const extra = $.SUBRULE($.extraRule)
            $.CONSUME(NewLine)
            return removeUndefined({...attr, nesting, ...extra})
        })

        this.entityRule = $.RULE<() => EntityAst>('entityRule', () => {
            const {entity, ...namespace} = $.SUBRULE($.entityRefRule)
            $.OPTION(() => $.CONSUME(WhiteSpace))
            const alias = $.OPTION2(() => {
                $.CONSUME(As)
                $.CONSUME2(WhiteSpace)
                return $.SUBRULE($.identifierRule)
            })
            $.OPTION3(() => $.CONSUME3(WhiteSpace))
            const extra = $.SUBRULE($.extraRule)
            $.CONSUME(NewLine)
            const attrs: AttributeAstFlat[] = []
            $.MANY(() => attrs.push($.SUBRULE($.attributeRule)))
            return removeUndefined({statement: 'Entity' as const, name: entity, ...namespace, alias, ...extra, attrs: nestAttributes(attrs)})
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
            const {kind, ref, polymorphic} = $.SUBRULE(attributeRelationRule)
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
            const {entity, ...namespace} = $.SUBRULE(this.entityRefRule)
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
    if (parser.errors.length > 0) {
        return ParserResult.failure(parser.errors.map(formatError))
    }
    return ParserResult.success(res)
}

export function parseAmlAst(input: string): ParserResult<AmlAst> {
    return parseRule(p => p.amlRule(), input)
}

function formatError(err: IRecognitionException): ParserError {
    const {offset, line, column} = parserInfo(err.token)
    return {name: err.name, message: err.message, position: {offset, line, column}}
}

function parserInfo(token: IToken): TokenInfo {
    return {
        token: token.tokenType?.name || 'missing',
        offset: [token.startOffset, token.endOffset || 0],
        line: [token.startLine || 0, token.endLine || 0],
        column: [token.startColumn || 0, token.endColumn || 0]
    }
}

// utils functions

export function nestAttributes(attributes: AttributeAstFlat[]): AttributeAstNested[] {
    const results: AttributeAstNested[] = []
    let path: IdentifierAst[] = []
    let parents: AttributeAstNested[] = []
    let curNesting = 0
    attributes.forEach(attribute => {
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
