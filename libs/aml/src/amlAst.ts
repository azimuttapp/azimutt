import {arraySame, findMap, isObject} from "@azimutt/utils";
import {
    EditorPosition,
    isParserErrorLevel,
    isTokenPosition,
    ParserErrorLevel,
    RelationCardinality,
    TokenEditor,
    TokenPosition
} from "@azimutt/models";

// statements
export type AmlAst = StatementsAst
export type StatementsAst = { statements: StatementAst[] }
export type StatementAst = { meta: TokenInfo } & (NamespaceStatement | EntityStatement | RelationStatement | TypeStatement | EmptyStatement)
export type NamespaceStatement = { kind: 'Namespace', line: number } & NamespaceRefAst& ExtraAst
export type EntityStatement = { kind: 'Entity', name: IdentifierAst, view?: TokenInfo, alias?: IdentifierAst, attrs?: AttributeAstNested[] } & NamespaceRefAst & ExtraAst
export type RelationStatement = { kind: 'Relation', src: AttributeRefCompositeAst, srcCardinality: RelationCardinalityAst, polymorphic?: RelationPolymorphicAst, refCardinality: RelationCardinalityAst, ref: AttributeRefCompositeAst } & ExtraAst
export type TypeStatement = { kind: 'Type', name: IdentifierAst, content?: TypeContentAst } & NamespaceRefAst & ExtraAst
export type EmptyStatement = { kind: 'Empty', comment?: CommentAst }

// clauses
export type AttributeAstFlat = { meta: TokenInfo, nesting: {token: TokenInfo, depth: number}, name: IdentifierAst, nullable?: TokenInfo } & AttributeTypeAst & { constraints?: AttributeConstraintAst[] } & ExtraAst
export type AttributeAstNested = { meta: TokenInfo, path: IdentifierAst[], nullable?: TokenInfo } & AttributeTypeAst & { constraints?: AttributeConstraintAst[] } & ExtraAst & { attrs?: AttributeAstNested[], warning?: TokenInfo }
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

// functions

export type AmlToken = DatabaseToken | CatalogToken | SchemaToken | EntityToken | AttributeToken | TypeToken
export type DatabaseToken = { kind: 'Database', position: TokenPosition, database: IdentifierAst }
export type CatalogToken = { kind: 'Catalog', position: TokenPosition, catalog: IdentifierAst, database?: IdentifierAst }
export type SchemaToken = { kind: 'Schema', position: TokenPosition, schema: IdentifierAst, catalog?: IdentifierAst, database?: IdentifierAst }
export type EntityToken = { kind: 'Entity', position: TokenPosition, entity: IdentifierAst } & NamespaceRefAst
export type AttributeToken = { kind: 'Attribute', position: TokenPosition, path: IdentifierAst[], entity: IdentifierAst } & NamespaceRefAst
export type TypeToken = { kind: 'Type', position: TokenPosition, type: IdentifierAst } & NamespaceRefAst
// add more: keyword, alias, propertyName...

export function findTokenAt(ast: AmlAst, position: EditorPosition): AmlToken | undefined {
    const s = ast.statements.find(s => isInside(position, s.meta.position))
    if (s?.kind === 'Entity') {
        if (inside(position, s.name)) return entityToken({...s, entity: s.name})
        if (s.schema && inside(position, s.schema)) return schemaToken(s.schema, s)
        // TODO: if (s.catalog && inside(position, s.catalog)) return {kind: 'Catalog', range: toRange(s.catalog), catalog: s.catalog.value, database: s.database?.value}
        // TODO: if (s.database && inside(position, s.database)) return {kind: 'Database', range: toRange(s.database), database: s.database.value}
        const a = flattenAttrs(s.attrs).find(a => isInside(position, a.meta.position))
        if (a) {
            const name = a.path[a.path.length - 1]
            if (name && inside(position, name)) return attributeToken(a.path, {...s, entity: s.name})
            const r = findMap(a.constraints || [], c => {
                if (c.kind === 'Relation') {
                    if (inside(position, c.ref.entity)) return entityToken(c.ref)
                    if (c.ref.schema && inside(position, c.ref.schema)) return schemaToken(c.ref.schema, c.ref)
                    // TODO: rename attribute
                }
            })
            if (r) return r
        }
    } else if (s?.kind === 'Relation') {
        if (inside(position, s.src.entity)) return entityToken(s.src)
        if (inside(position, s.ref.entity)) return entityToken(s.ref)
        if (s.src.schema && inside(position, s.src.schema)) return schemaToken(s.src.schema, s.src)
        if (s.ref.schema && inside(position, s.ref.schema)) return schemaToken(s.ref.schema, s.ref)
        const src = findMap(s.src.attrs, ({path = [], ...a}) => {
            if (inside(position, a)) return attributeToken([a], s.src)
            const i = path.findIndex(p => inside(position, p))
            if (i >= 0) return attributeToken([a, ...path.slice(0, i + 1)], s.src)
        })
        if (src) return src
        const ref = findMap(s.ref.attrs, ({path = [], ...a}) => {
            if (inside(position, a)) return attributeToken([a], s.ref)
            const i = path.findIndex(p => inside(position, p))
            if (i >= 0) return attributeToken([a, ...path.slice(0, i + 1)], s.ref)
        })
        if (ref) return ref
    }
    // TODO: else if (s?.kind === 'Type') {}
    // TODO: else if (s?.kind === 'Namespace') {}
    return undefined
}

export function collectTokenPositions(ast: AmlAst, token: AmlToken): TokenPosition[] {
    const tokens: IdentifierAst[] = []
    ast.statements.forEach(statement => {
        if (statement.kind === 'Entity') {
            if (token.kind === 'Entity' && sameEntity(token, {...statement, entity: statement.name})) tokens.push(statement.name)
            if (token.kind === 'Schema' && statement.schema && sameSchema(token, statement)) tokens.push(statement.schema)
            flattenAttrs(statement.attrs).forEach(attr => {
                if (token.kind === 'Attribute' && sameAttribute(token, {...statement, entity: statement.name}, attr.path)) tokens.push(attr.path[attr.path.length - 1])
                attr.constraints?.forEach(c => {
                    if (c.kind === 'Relation') {
                        if (token.kind === 'Entity' && sameEntity(token, c.ref)) tokens.push(c.ref.entity)
                        if (token.kind === 'Schema' && token.schema.value === c.ref.schema?.value) tokens.push(c.ref.schema)
                        c.ref.attrs.forEach(a => {
                            if (token.kind === 'Attribute' && sameAttribute(token, c.ref, [a, ...a.path || []])) tokens.push(a)
                        })
                    }
                })
            })
        } else if (statement.kind === 'Relation') {
            if (token.kind === 'Entity' && sameEntity(token, statement.src)) tokens.push(statement.src.entity)
            if (token.kind === 'Entity' && sameEntity(token, statement.ref)) tokens.push(statement.ref.entity)
            if (token.kind === 'Schema' && statement.src.schema && sameSchema(token, statement.src)) tokens.push(statement.src.schema)
            if (token.kind === 'Schema' && statement.ref.schema && sameSchema(token, statement.ref)) tokens.push(statement.ref.schema)
            statement.src.attrs.forEach(a => {
                if (token.kind === 'Attribute' && sameAttribute(token, statement.src, [a, ...a.path || []])) tokens.push(a)
            })
            statement.ref.attrs.forEach(a => {
                if (token.kind === 'Attribute' && sameAttribute(token, statement.ref, [a, ...a.path || []])) tokens.push(a)
            })
        }
    })
    return tokens.map(t => t.token)
}

function sameSchema(token: SchemaToken, ref: NamespaceRefAst): boolean {
    return token.database?.value === ref.database?.value && token.catalog?.value === ref.catalog?.value && token.schema.value === ref.schema?.value
}
function sameEntity(token: EntityToken, ref: EntityRefAst): boolean {
    return token.database?.value === ref.database?.value && token.catalog?.value === ref.catalog?.value && token.schema?.value === ref.schema?.value && token.entity.value === ref.entity.value
}
function sameAttribute(token: AttributeToken, ref: EntityRefAst, path: IdentifierAst[]): boolean {
    return token.database?.value === ref.database?.value && token.catalog?.value === ref.catalog?.value && token.schema?.value === ref.schema?.value && token.entity.value === ref.entity.value && samePath(token.path, path)
}

export function flattenAttrs(attrs: AttributeAstNested[] | undefined): AttributeAstNested[] {
    return (attrs || []).flatMap(a => [a, ...flattenAttrs(a.attrs)])
}

export function isInside(position: EditorPosition, token: TokenEditor): boolean {
    const line = position.line
    const col = position.column
    const inLines = token.start.line < line && line < token.end.line
    const startLine = line === token.start.line && token.start.column <= col && (col <= token.end.column || line < token.end.line)
    const endLine = line === token.end.line && col <= token.end.column && (token.start.column <= col || token.start.line < line)
    return inLines || startLine || endLine
}
const inside = (position: EditorPosition, value: {token: TokenInfo}): boolean => isInside(position, value.token.position)
const samePath = (p1: IdentifierAst[], p2: IdentifierAst[]): boolean => arraySame(p1, p2, (a, b) => a.value === b.value)
const schemaToken = (schema: IdentifierAst, n: NamespaceRefAst): SchemaToken => ({kind: 'Schema', position: schema.token, schema: schema, catalog: n.catalog, database: n.database})
const entityToken = (ref: EntityRefAst): EntityToken => ({kind: 'Entity', position: ref.entity.token, entity: ref.entity, schema: ref.schema, catalog: ref.catalog, database: ref.database})
const attributeToken = (path: IdentifierAst[], ref: EntityRefAst): AttributeToken => ({kind: 'Attribute', position: path[path.length - 1].token, path, entity: ref.entity, schema: ref.schema, catalog: ref.catalog, database: ref.database})
