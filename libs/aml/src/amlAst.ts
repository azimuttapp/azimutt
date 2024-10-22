import {isObject} from "@azimutt/utils";
import {
    isParserErrorLevel,
    isTokenPosition,
    ParserErrorLevel,
    RelationCardinality,
    TokenPosition
} from "@azimutt/models";

// statements
export type AmlAst = StatementAst[]
export type StatementAst = NamespaceStatement | EntityStatement | RelationStatement | TypeStatement | EmptyStatement
export type NamespaceStatement = { kind: 'Namespace', line: number, schema?: IdentifierAst, catalog?: IdentifierAst, database?: IdentifierAst } & ExtraAst
export type EntityStatement = { kind: 'Entity', name: IdentifierAst, view?: TokenInfo, alias?: IdentifierAst, attrs?: AttributeAstNested[] } & NamespaceRefAst & ExtraAst
export type RelationStatement = { kind: 'Relation', src: AttributeRefCompositeAst, srcCardinality: RelationCardinalityAst, polymorphic?: RelationPolymorphicAst, refCardinality: RelationCardinalityAst, ref: AttributeRefCompositeAst } & ExtraAst & { warning?: TokenInfo }
export type TypeStatement = { kind: 'Type', name: IdentifierAst, content?: TypeContentAst } & NamespaceRefAst & ExtraAst
export type EmptyStatement = { kind: 'Empty', comment?: CommentAst }

// clauses
export type AttributeAstFlat = { nesting: {token: TokenInfo, depth: number}, name: IdentifierAst, nullable?: TokenInfo } & AttributeTypeAst & { constraints?: AttributeConstraintAst[] } & ExtraAst
export type AttributeAstNested = { path: IdentifierAst[], nullable?: TokenInfo } & AttributeTypeAst & { constraints?: AttributeConstraintAst[] } & ExtraAst & { attrs?: AttributeAstNested[], warning?: TokenInfo }
export type AttributeTypeAst = { type?: IdentifierAst, enumValues?: AttributeValueAst[], defaultValue?: AttributeValueAst }
export type AttributeConstraintAst = AttributePkAst | AttributeUniqueAst | AttributeIndexAst | AttributeCheckAst | AttributeRelationAst
export type AttributePkAst = { kind: 'PrimaryKey', token: TokenInfo, name?: IdentifierAst }
export type AttributeUniqueAst = { kind: 'Unique', token: TokenInfo, name?: IdentifierAst }
export type AttributeIndexAst = { kind: 'Index', token: TokenInfo, name?: IdentifierAst }
export type AttributeCheckAst = { kind: 'Check', token: TokenInfo, name?: IdentifierAst, predicate?: ExpressionAst }
export type AttributeRelationAst = { kind: 'Relation', token: TokenInfo, srcCardinality: RelationCardinalityAst, polymorphic?: RelationPolymorphicAst, refCardinality: RelationCardinalityAst, ref: AttributeRefCompositeAst, warning?: TokenInfo }

export type RelationCardinalityAst = { kind: RelationCardinality, token: TokenInfo }
export type RelationPolymorphicAst = { attr: AttributePathAst, value: AttributeValueAst }

export type TypeContentAst = TypeAliasAst | TypeEnumAst | TypeStructAst | TypeCustomAst
export type TypeAliasAst = { kind: 'Alias', name: IdentifierAst }
export type TypeEnumAst = { kind: 'Enum', values: AttributeValueAst[] }
export type TypeStructAst = { kind: 'Struct', attrs: AttributeAstNested[] }
export type TypeCustomAst = { kind: 'Custom', definition: ExpressionAst }

// basic parts
export type NamespaceRefAst = { database?: IdentifierAst, catalog?: IdentifierAst, schema?: IdentifierAst }
export type EntityRefAst = { entity: IdentifierAst } & NamespaceRefAst
export type AttributePathAst = IdentifierAst & { path?: IdentifierAst[] }
export type AttributeRefAst = EntityRefAst & { attr: AttributePathAst, warning?: TokenInfo }
export type AttributeRefCompositeAst = EntityRefAst & { attrs: AttributePathAst[], warning?: TokenInfo }
export type AttributeValueAst = NullAst | DecimalAst | IntegerAst | BooleanAst | ExpressionAst | IdentifierAst // TODO: add date

export type ExtraAst = { properties?: PropertiesAst, doc?: DocAst, comment?: CommentAst }
export type PropertiesAst = PropertyAst[]
export type PropertyAst = { key: IdentifierAst, sep?: TokenInfo, value?: PropertyValueAst }
export type PropertyValueAst = NullAst | DecimalAst | IntegerAst | BooleanAst | ExpressionAst | IdentifierAst | PropertyValueAst[]
export type DocAst = { kind: 'Doc', token: TokenInfo, value: string, multiLine?: boolean }

// elements
export type ExpressionAst = { kind: 'Expression', token: TokenInfo, value: string }
export type IdentifierAst = { kind: 'Identifier', token: TokenInfo, value: string, quoted?: boolean }
export type IntegerAst = { kind: 'Integer', token: TokenInfo, value: number }
export type DecimalAst = { kind: 'Decimal', token: TokenInfo, value: number }
export type BooleanAst = { kind: 'Boolean', token: TokenInfo, value: boolean }
export type NullAst = { kind: 'Null', token: TokenInfo }
export type CommentAst = { kind: 'Comment', token: TokenInfo, value: string }

// helpers
export type TokenInfo = TokenPosition & { issues?: TokenIssue[] }
export type TokenIssue = { message: string, kind: string, level: ParserErrorLevel }

export const isTokenInfo = (value: unknown): value is TokenInfo => isTokenPosition(value) && (!('issues' in value) || ('issues' in value && Array.isArray(value.issues) && value.issues.every(isTokenIssue)))
export const isTokenIssue = (value: unknown): value is TokenIssue => isObject(value) && ('message' in value && typeof value.message === 'string') && ('kind' in value && typeof value.kind === 'string') && ('level' in value && isParserErrorLevel(value.level))

// other helper types
export const amlKeywords = ['namespace', 'as', 'nullable', 'pk', 'fk', 'index', 'unique', 'check', 'rel', 'type']
export type PropertyValueBasic = null | number | boolean | string
export type PropertyValue = PropertyValueBasic | PropertyValueBasic[]
