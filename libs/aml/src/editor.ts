import {anyAsString, arraySame, distinct, findMap} from "@azimutt/utils";
import {
    Attribute,
    attributeExtraKeys,
    attributePathFromId,
    attributesRefFromId,
    Database,
    EditorPosition,
    Entity,
    entityExtraKeys,
    entityRefFromId,
    entityRefSame,
    entityRefToId,
    entityToRef,
    Extra,
    flattenAttributes,
    getAttribute,
    Relation,
    RelationAction,
    relationExtraKeys,
    TokenEditor,
    TokenPosition,
    Type,
    typeToId
} from "@azimutt/models";
import {AmlAst, AttributeAstNested, EntityRefAst, IdentifierAst, NamespaceRefAst, TokenInfo} from "./amlAst";
import {genAttributeRef} from "./amlGenerator";

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
        const e = findEntityTokenAt({...s, entity: s.name}, position)
        if (e) return e
        const a = flattenAttrs(s.attrs).find(a => isInside(position, a.meta.position))
        if (a) {
            const name = a.path[a.path.length - 1]
            if (name && inside(position, name)) return attributeToken(a.path, {...s, entity: s.name})
            const r = findMap(a.constraints || [], c => {
                if (c.kind === 'Relation') {
                    const e = findEntityTokenAt(c.ref, position)
                    if (e) return e
                    // TODO: rename attribute
                }
            })
            if (r) return r
        }
    } else if (s?.kind === 'Relation') {
        const st = findEntityTokenAt(s.src, position) || findEntityTokenAt(s.ref, position)
        if (st) return st
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
    } else if (s?.kind === 'Type') {
        const n = findNamespaceTokenAt(s, position)
        if (n) return n
    } else if (s?.kind === 'Namespace') {
        const n = findNamespaceTokenAt(s, position)
        if (n) return n
    }
    return undefined
}

function findEntityTokenAt(ref: EntityRefAst, position: EditorPosition): AmlToken | undefined {
    if (inside(position, ref.entity)) return entityToken(ref)
    return findNamespaceTokenAt(ref, position)
}

function findNamespaceTokenAt(ref: NamespaceRefAst, position: EditorPosition): AmlToken | undefined {
    if (ref.schema && inside(position, ref.schema)) return schemaToken(ref.schema, ref)
    if (ref.catalog && inside(position, ref.catalog)) return catalogToken(ref.catalog, ref)
    if (ref.database && inside(position, ref.database)) return databaseToken(ref.database)
}

export function collectTokenPositions(ast: AmlAst, token: AmlToken): TokenPosition[] {
    const tokens: IdentifierAst[] = []
    ast.statements.forEach(statement => {
        if (statement.kind === 'Entity') {
            tokens.push(...collectEntityTokenPositions({...statement, entity: statement.name}, token))
            flattenAttrs(statement.attrs).forEach(attr => {
                if (token.kind === 'Attribute' && sameAttribute(token, {...statement, entity: statement.name}, attr.path)) tokens.push(attr.path[attr.path.length - 1])
                attr.constraints?.forEach(c => {
                    if (c.kind === 'Relation') {
                        tokens.push(...collectEntityTokenPositions(c.ref, token))
                        c.ref.attrs.forEach(a => {
                            if (token.kind === 'Attribute' && sameAttribute(token, c.ref, [a, ...a.path || []])) tokens.push(a)
                        })
                    }
                })
            })
        } else if (statement.kind === 'Relation') {
            tokens.push(...collectEntityTokenPositions(statement.src, token))
            tokens.push(...collectEntityTokenPositions(statement.ref, token))
            statement.src.attrs.forEach(a => {
                if (token.kind === 'Attribute' && sameAttribute(token, statement.src, [a, ...a.path || []])) tokens.push(a)
            })
            statement.ref.attrs.forEach(a => {
                if (token.kind === 'Attribute' && sameAttribute(token, statement.ref, [a, ...a.path || []])) tokens.push(a)
            })
        } else if (statement.kind === 'Type') {
            tokens.push(...collectNamespaceTokenPositions(statement, token))
        } else if (statement.kind === 'Namespace') {
            tokens.push(...collectNamespaceTokenPositions(statement, token))
        }
    })
    return tokens.map(t => t.token)
}

function collectEntityTokenPositions(ref: EntityRefAst, token: AmlToken): IdentifierAst[] {
    if (token.kind === 'Entity' && sameEntity(token, ref)) return [ref.entity]
    return collectNamespaceTokenPositions(ref, token)
}

function collectNamespaceTokenPositions(ref: NamespaceRefAst, token: AmlToken): IdentifierAst[] {
    if (token.kind === 'Schema' && ref.schema && sameSchema(token, ref)) return [ref.schema]
    if (token.kind === 'Catalog' && ref.catalog && sameCatalog(token, ref)) return [ref.catalog]
    if (token.kind === 'Database' && ref.database && sameDatabase(token, ref)) return [ref.database]
    return []
}

function sameDatabase(token: DatabaseToken, ref: NamespaceRefAst): boolean {
    return token.database.value === ref.database?.value
}
function sameCatalog(token: CatalogToken, ref: NamespaceRefAst): boolean {
    return token.database?.value === ref.database?.value && token.catalog.value === ref.catalog?.value
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
const databaseToken = (database: IdentifierAst): DatabaseToken => ({kind: 'Database', position: database.token, database})
const catalogToken = (catalog: IdentifierAst, n: NamespaceRefAst): CatalogToken => ({kind: 'Catalog', position: catalog.token, catalog, database: n.database})
const schemaToken = (schema: IdentifierAst, n: NamespaceRefAst): SchemaToken => ({kind: 'Schema', position: schema.token, schema, catalog: n.catalog, database: n.database})
const entityToken = (ref: EntityRefAst): EntityToken => ({kind: 'Entity', position: ref.entity.token, entity: ref.entity, schema: ref.schema, catalog: ref.catalog, database: ref.database})
const attributeToken = (path: IdentifierAst[], ref: EntityRefAst): AttributeToken => ({kind: 'Attribute', position: path[path.length - 1].token, path, entity: ref.entity, schema: ref.schema, catalog: ref.catalog, database: ref.database})

// completion

export type SuggestionKind = 'entity' | 'attribute' | 'pk' | 'index' | 'unique' | 'check' | 'property' | 'value' | 'relation' | 'type' | 'default'
export type Suggestion = { kind: SuggestionKind, insert: string, label?: string, documentation?: string }

export function computeSuggestions(beforeCursor: string, prevLine: string, db: Database): Suggestion[] {
    const suggestions: Suggestion[] = []
    const entities: Entity[] = db.entities || []
    const attributes: Attribute[] = entities.flatMap(e => flattenAttributes(e.attrs))
    const relations: Relation[] = db.relations || []
    const types: Type[] = db.types || []
    let res: string[] | undefined // storing match result
    if (beforeCursor === '') {
        suggestions.push({kind: 'entity', insert: '${1:entity}\n  id uuid pk\n  ', label: 'Add entity'})
        suggestions.push({kind: 'relation', insert: 'rel ${1:from_entity}(${2:from_attribute}) -> ${3:to_entity}(${4:to_attribute})', label: 'Add relation'})
    }
    if (res = completionMatch(beforeCursor, /^ +$/)) {
        const indent = beforeCursor.length % 2 === 0 ? '' : ' '
        suggestions.push({kind: 'attribute', insert: indent + '${1:name} ${2:type}', label: 'Add attribute'})
    }
    if (res = entityWrittenMatch(beforeCursor)) {
        const [name] = res
        if (name === 'rel') {
            entities.map(e => ({kind: 'entity' as const, insert: entityRefToId(entityToRef(e))}))
                .filter(s => s.insert !== 're') // it's generated by typing the `rel` keyword ^^
                .forEach(s => suggestions.push(s))
        } else if (name === 'type') {
            // nothing yet
        } else {
            suggestExtra(suggestions, '')
        }
    }
    if (attributeIndentationMatch(beforeCursor)) {
        if (prevLine.match(/^[a-zA-Z_][a-zA-Z0-9_#]*/)) { // on first attribute
            suggestions.push({kind: 'attribute', insert: '  id uuid pk'.replace(beforeCursor, '')})
            suggestions.push({kind: 'attribute', insert: '  id bigint pk {autoIncrement}'.replace(beforeCursor, '')})
        }
    }
    if (res = attributeNameWrittenMatch(beforeCursor)) {
        const [attributeName] = res
        if (attributeName === 'id' && !!prevLine.match(/^[a-zA-Z_][a-zA-Z0-9_#]*/)) { // on first attribute
            suggestions.push({kind: 'type', insert: 'uuid pk'})
            suggestions.push({kind: 'type', insert: 'bigint pk {autoIncrement}'})
        }
        if (attributeName.endsWith('_id') || attributeName.endsWith('Id')) {
            suggestRelationRef(suggestions, entities, 1, '-> ')
        }
        if (attributeName.endsWith('_at') || attributeName.endsWith('At')) {
            suggestions.push({kind: 'type', insert: 'timestamp=`now()`'})
        }
        suggestAttributeType(types, attributes, suggestions)
    }
    if (attributeTypeWrittenMatch(beforeCursor)) { // wrote attribute type
        const [, indent] = beforeCursor.match(/^( +)/) || []
        suggestAttributeProps(suggestions)
        suggestExtra(suggestions, indent)
    }
    if (res = attributeRootMatch(beforeCursor)) {
        const [refId] = res
        const attrs = entities.find(e => entityRefSame(entityToRef(e), entityRefFromId(refId)))?.attrs || []
        attrs.forEach(attr => suggestions.push({kind: 'attribute', insert: attr.name}))
    }
    if (res = attributeNestedMatch(beforeCursor)) {
        const [refId, pathId] = res
        const attrs = entities.find(e => entityRefSame(entityToRef(e), entityRefFromId(refId)))?.attrs
        const children = getAttribute(attrs, attributePathFromId(pathId))?.attrs || []
        children.forEach(attr => suggestions.push({kind: 'attribute', insert: attr.name}))
    }
    if (relationLinkWrittenMatch(beforeCursor)) {
        suggestRelationRef(suggestions, entities, undefined, '')
    }
    if (res = relationSrcWrittenMatch(beforeCursor)) {
        const [srcId] = res
        // TODO: sort target attributes in the same order then src if possible
        suggestRelationRef(suggestions, entities, attributesRefFromId(srcId).attrs.length, '-> ')
    }
    if (res = entityPropsKeyMatch(beforeCursor)) {
        if (!res.includes('view')) suggestions.push({kind: 'property', insert: 'view: "${1:query}"', label: 'view'})
        if (!res.includes('color')) suggestions.push({kind: 'property', insert: 'color:', label: 'color'})
        if (!res.includes('tags')) suggestions.push({kind: 'property', insert: 'tags: [${1:tag}]', label: 'tags'})
        suggestPropKeys(entities, entityExtraKeys, suggestions)
    }
    if (res = entityPropsValueMatch(beforeCursor)) {
        const [prop] = res
        if (prop === 'color') 'red orange amber yellow lime green emerald teal cyan sky blue indigo violet purple fuchsia pink rose gray'.split(' ').forEach(color => suggestions.push({kind: 'value', insert: color}))
        if (prop === 'tags') suggestTagValues(entities.flatMap(e => e.extra?.tags || []), suggestions)
        if (!entityExtraKeys.includes(prop)) suggestPropValues(entities.map(e => e.extra?.[prop]), suggestions)
    }
    if (res = attributePropsKeyMatch(beforeCursor)) {
        if (!res.includes('autoIncrement')) suggestions.push({kind: 'property', insert: 'autoIncrement'})
        if (!res.includes('hidden')) suggestions.push({kind: 'property', insert: 'hidden'})
        if (!res.includes('tags')) suggestions.push({kind: 'property', insert: 'tags: [${1:tag}]', label: 'tags'})
        suggestPropKeys(attributes, attributeExtraKeys, suggestions)
    }
    if (res = attributePropsValueMatch(beforeCursor)) {
        const [prop] = res
        if (prop === 'tags') suggestTagValues(attributes.flatMap(a => a.extra?.tags || []), suggestions)
        if (!attributeExtraKeys.includes(prop)) suggestPropValues(attributes.map(a => a.extra?.[prop]), suggestions)
    }
    if (res = relationPropsKeyMatch(beforeCursor)) {
        if (!res.includes('onUpdate')) suggestions.push({kind: 'property', insert: 'onUpdate:', label: 'onUpdate'})
        if (!res.includes('onDelete')) suggestions.push({kind: 'property', insert: 'onDelete:', label: 'onDelete'})
        if (!res.includes('tags')) suggestions.push({kind: 'property', insert: 'tags: [${1:tag}]', label: 'tags'})
        suggestPropKeys(relations, relationExtraKeys, suggestions)
    }
    if (res = relationPropsValueMatch(beforeCursor)) {
        const [prop] = res
        if (prop === 'onUpdate' || prop === 'onDelete') Object.keys(RelationAction.enum).forEach(action => suggestions.push({kind: 'value', insert: action.includes(' ') ? '"' + action + '"' : action}))
        if (prop === 'tags') suggestTagValues(relations.flatMap(r => r.extra?.tags || []), suggestions)
        if (!relationExtraKeys.includes(prop)) suggestPropValues(attributes.map(r => r.extra?.[prop]), suggestions)
    }
    // TODO: suggest attribute missing options even when some are already set
    // TODO: relation written => extra
    // TODO: type written => extra
    return suggestions
}

const completionMatch = (line: string, regex: RegExp): string[] | undefined => {
    const res = line.match(regex)
    return res ? [...res.slice(1)] : undefined
}
const entityNameR = '[a-zA-Z_][a-zA-Z0-9_#]*' // miss quoted name
const entityRefR = '[a-zA-Z_][a-zA-Z0-9_#.]*' // too simplistic (just allowing '.' to capture all segments)
const attributeNameR = '[a-zA-Z_][a-zA-Z0-9_#]*' // miss quoted name
const attributeTypeR = '[a-zA-Z_][a-zA-Z0-9_#]*'
const attributePathR = '[a-zA-Z_][a-zA-Z0-9_#.]*' // too simplistic (just allowing '.' to capture all segments)
const attributeValueR = '[a-zA-Z0-9_]+'
const attributePathsR = ' *[a-zA-Z_][a-zA-Z0-9_#., ]*' // too simplistic (just allowing '.', ' ' and ',' to capture everything)
const relationCardinalityR = '[-<>]'
const propKeyR = '[a-zA-Z0-9]+'
const propValueR = '[^,]+'
const relationPolyR = `${attributeNameR}=${attributeValueR}`
const startsWithKeyword = (line: string): boolean => line.startsWith('namespace ') || line.startsWith('rel ') || line.startsWith('fr ') || line.startsWith('type ')
export const entityWrittenMatch = (line: string): string[] | undefined => startsWithKeyword(line) ? undefined : completionMatch(line, new RegExp(`^(${entityNameR}) +$`))
export const attributeIndentationMatch = (line: string): string[] | undefined => completionMatch(line, new RegExp(`^( +)$`))
export const attributeNameWrittenMatch = (line: string): string[] | undefined => completionMatch(line, new RegExp(`^ +(${attributeNameR}) +$`))
export const attributeTypeWrittenMatch = (line: string): string[] | undefined => completionMatch(line, new RegExp(`^ +(${attributeNameR}) +(${attributeTypeR}) +$`))
export const attributeRootMatch = (line: string): string[] | undefined => completionMatch(line, new RegExp(`(${entityRefR})\\((?: *${attributePathR} *,)* *$`))
export const attributeNestedMatch = (line: string): string[] | undefined => completionMatch(line, new RegExp(`(${entityRefR})\\((?: *${attributePathR} *,)* *(${attributePathR})\\.$`))
export const relationLinkWrittenMatch = (line: string): string[] | undefined => completionMatch(line, new RegExp(`(${relationCardinalityR})(${relationPolyR})?(${relationCardinalityR}) +$`))
export const relationSrcWrittenMatch = (line: string): string[] | undefined => completionMatch(line, new RegExp(`^rel +(${entityRefR}\\(${attributePathsR}\\)) +$`))
export const entityPropsKeyMatch = (line: string): string[] | undefined => startsWithKeyword(line) ? undefined : completionMatch(line, new RegExp(`^${entityNameR} +.*{((?: *${propKeyR} *(?:: *${propValueR} *)?,)*) *$`))?.flatMap(m => m.split(',')).map(p => p.split(':')[0].trim()).filter(k => !!k)
export const entityPropsValueMatch = (line: string): string[] | undefined => startsWithKeyword(line) ? undefined : completionMatch(line, new RegExp(`^${entityNameR} +.*{(?: *${propKeyR} *(?:: *${propValueR} *)?,)* *(${propKeyR}) *: *[["]?$`))
export const attributePropsKeyMatch = (line: string): string[] | undefined => completionMatch(line, new RegExp(`^ +${attributeNameR} +.*{((?: *${propKeyR} *(?:: *${propValueR} *)?,)*) *$`))?.flatMap(m => m.split(',')).map(p => p.split(':')[0].trim()).filter(k => !!k)
export const attributePropsValueMatch = (line: string): string[] | undefined => completionMatch(line, new RegExp(`^ +${attributeNameR} +.*{(?: *${propKeyR} *(?:: *${propValueR} *)?,)* *(${propKeyR}) *: *[["]?$`))
export const relationPropsKeyMatch = (line: string): string[] | undefined => completionMatch(line, new RegExp(`^rel +.*{((?: *${propKeyR} *(?:: *${propValueR} *)?,)*) *$`))?.flatMap(m => m.split(',')).map(p => p.split(':')[0].trim()).filter(k => !!k)
export const relationPropsValueMatch = (line: string): string[] | undefined => completionMatch(line, new RegExp(`^rel +.*{(?: *${propKeyR} *(?:: *${propValueR} *)?,)* *(${propKeyR}) *: *[["]?$`))


export function suggestAttributeType(types: Type[], attributes: Attribute[], suggestions: Suggestion[]): void {
    const toSuggest = ['varchar', 'text', 'integer', 'bigint', 'boolean', 'uuid', 'timestamp', '"timestamp with time zone"', 'json', 'jsonb', 'string', 'number'].concat(types.map(typeToId), attributes.map(a => a.type))
    distinct(toSuggest).forEach(type => suggestions.push({kind: 'type', insert: type}))
}
function suggestAttributeProps(suggestions: Suggestion[]): void {
    suggestions.push({kind: 'pk', insert: 'pk'})
    suggestions.push({kind: 'unique', insert: 'unique'})
    suggestions.push({kind: 'index', insert: 'index'})
    suggestions.push({kind: 'check', insert: 'check(`${1:predicate}`)', label: 'check'})
    suggestions.push({kind: 'relation', insert: '->'})
}
function suggestPropKeys(items: {extra?: Extra}[], ignore: string[], suggestions: Suggestion[]): void {
    const props: string[] = items.flatMap(i => Object.keys(i.extra || {}).filter(k => !ignore.includes(k)))
    distinct(props).forEach(prop => suggestions.push({kind: 'property', insert: `${prop}:`, label: prop}))
}
export function suggestRelationRef(suggestions: Suggestion[], entities: Entity[], attrs: number | undefined, prefix: string): void {
    entities.map(e => e.pk && (attrs === undefined || e.pk.attrs.length === attrs) ? prefix + genAttributeRef({...entityToRef(e), attrs: e.pk.attrs}, {}, false, undefined, false) : '')
        .filter(rel => !!rel)
        .forEach(rel => suggestions.push({kind: 'relation', insert: rel}))
}
function suggestTagValues(tags: string[], suggestions: Suggestion[]): void {
    distinct(tags).filter(tag => typeof tag === 'string').forEach(tag => suggestions.push({kind: 'value', insert: tag}))
}
function suggestPropValues(values: unknown[], suggestions: Suggestion[]): void {
    const vals = values.flatMap(v => Array.isArray(v) ? v : [v]).map(anyAsString).filter(v => !!v)
    distinct(vals).forEach(v => suggestions.push({kind: 'value', insert: v}))
}
export function suggestExtra(suggestions: Suggestion[], indent: string): void {
    suggestions.push({kind: 'default', insert: '{${1:key}: ${2:value}}', label: '{key: value}', documentation: 'add properties'})
    suggestions.push({kind: 'default', insert: '| ${1:your doc}', label: '| inline doc', documentation: 'add documentation'})
    suggestions.push({kind: 'default', insert: `|||\n${indent}  \${1:your doc}\n${indent}|||`, label: '||| multi-line doc', documentation: 'add documentation'})
    suggestions.push({kind: 'default', insert: '# ${1:your comment}', label: '# comment', documentation: 'add comment'})
}
