import {isObject} from "@azimutt/utils";
import {isParserErrorKind, isTokenPosition, ParserErrorKind, TokenPosition} from "@azimutt/models";

export type AmlAst = StatementAst[]
export type StatementAst = NamespaceStatement | EntityStatement | RelationStatement | TypeStatement | EmptyStatement
export type NamespaceStatement = { statement: 'Namespace', schema: IdentifierToken, catalog?: IdentifierToken, database?: IdentifierToken } & ExtraAst
export type EntityStatement = { statement: 'Entity', name: IdentifierToken, view?: TokenInfo, alias?: IdentifierToken, attrs?: AttributeAstNested[] } & NamespaceRefAst & ExtraAst
export type RelationStatement = { statement: 'Relation', kind: RelationKindAst, src: AttributeRefCompositeAst, ref: AttributeRefCompositeAst, polymorphic?: RelationPolymorphicAst } & ExtraAst & { warning?: TokenInfo }
export type TypeStatement = { statement: 'Type', name: IdentifierToken, content?: TypeContentAst } & NamespaceRefAst & ExtraAst
export type EmptyStatement = { statement: 'Empty', comment?: CommentToken }

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

export type NamespaceRefAst = { database?: IdentifierToken, catalog?: IdentifierToken, schema?: IdentifierToken }
export type EntityRefAst = { entity: IdentifierToken } & NamespaceRefAst
export type AttributePathAst = IdentifierToken & { path?: IdentifierToken[] }
export type AttributeRefAst = EntityRefAst & { attr: AttributePathAst, warning?: TokenInfo }
export type AttributeRefCompositeAst = EntityRefAst & { attrs: AttributePathAst[], warning?: TokenInfo }
export type AttributeValueAst = NullToken | DecimalToken | IntegerToken | BooleanToken | ExpressionToken | IdentifierToken // TODO: add date

export type ExtraAst = { properties?: PropertiesAst, doc?: DocToken, comment?: CommentToken }
export type PropertiesAst = PropertyAst[]
export type PropertyAst = { key: IdentifierToken, sep?: TokenInfo, value?: PropertyValueAst }
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
