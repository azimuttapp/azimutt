import {groupBy, isNotUndefined, partition, removeEmpty, removeUndefined, zip} from "@azimutt/utils";
import {
    Attribute,
    AttributePath,
    attributePathSame,
    AttributeValue,
    Check,
    Database,
    Entity,
    EntityRef,
    Extra,
    Index,
    Namespace,
    ParserResult,
    Relation,
    RelationKind
} from "@azimutt/models";
import * as parser from "./parser";
import {version} from "./version";

export function parseAml(content: string): ParserResult<Database> {
    const start = Date.now()
    return parser.parseAml(content).map(ast => buildDatabase(ast, start, Date.now()))
}

export function generateAml(database: Database): string {
    return genDatabase(database)
}

// private functions 👇️ (some may be exported for tests)

const defaultType = 'unknown'

function buildDatabase(ast: parser.AmlAst, start: number, parsed: number): Database {
    const db: Database = {entities: [], relations: [], types: []}
    let namespace: Namespace = {}
    ast.filter(s => s.statement !== 'Empty').forEach((stmt, i) => {
        const index = i + 1
        if (stmt.statement === 'Namespace') {
            namespace = buildNamespace(index, stmt, namespace)
        } else if (stmt.statement === 'Entity') {
            const {entity, relations} = buildEntity(index, stmt, namespace)
            db.entities?.push(entity) // TODO: check if entity already exists
            relations.forEach(r => db.relations?.push(r))
        } else if (stmt.statement === 'Relation') {
            db.relations?.push(buildRelationStatement(index, stmt)) // TODO: check if relation already exists
        } else if (stmt.statement === 'Type') {
            // TODO: type
        } else {
            // Empty: do nothing
        }
    })
    const done = Date.now()
    return removeEmpty({...db, extra: {source: `AML parser ${version}`, parsedAt: new Date().toISOString(), parsingMs: parsed - start, formattingMs: done - parsed}})
}

function genDatabase(database: Database): string {
    const [entityRels, aloneRels] = partition(database.relations || [], r => {
        const statement = r.extra && 'statement' in r.extra && r.extra.statement
        return statement ? !!database.entities?.find(e => e.extra && 'statement' in e.extra && e.extra.statement === statement) : false
    })
    const entities = (database.entities || []).map((e, i) => {
        const statement = e.extra && 'statement' in e.extra && e.extra.statement
        const rels = statement ? entityRels.filter(r => r.extra && 'statement' in r.extra && r.extra.statement === statement) : []
        return {index: statement || i, aml: genEntity(e, rels)}
    })
    const entityCount = entities.length
    const relations = aloneRels.map((r, i) => {
        const statement = r.extra && 'statement' in r.extra && r.extra.statement
        return {index: statement || entityCount + i, aml: genRelation(r)}
    })
    return entities.concat(relations).sort((a, b) => a.index - b.index).map(a => a.aml).join('\n') || ''
}

function buildNamespace(statement: number, n: parser.NamespaceAst, current: Namespace): Namespace {
    const schema = n.schema.identifier
    const catalog = n.catalog?.identifier || current.catalog
    const database = n.database?.identifier || current.database
    return {schema, catalog, database}
}

function buildEntity(statement: number, e: parser.EntityAst, namespace: Namespace): { entity: Entity, relations: Relation[] } {
    const astNamespace = removeUndefined({schema: e.schema?.identifier, catalog: e.catalog?.identifier, database: e.database?.identifier})
    const entityNamespace = {...namespace, ...astNamespace}
    const attrs = e.attrs.map(a => buildAttribute(statement, a, {...entityNamespace, entity: e.name.identifier}))
    const flatAttrs = flattenAttributes(e.attrs)
    const pkAttrs = flatAttrs.filter(a => a.primaryKey)
    const indexes: Index[] = buildIndexes(flatAttrs.map(a => ({path: a.path.map(p => p.identifier), index: a.index ? a.index.value?.identifier || '' : undefined}))).map(i => removeUndefined({name: i.value, attrs: i.attrs}))
    const uniques: Index[] = buildIndexes(flatAttrs.map(a => ({path: a.path.map(p => p.identifier), index: a.unique ? a.unique.value?.identifier || '' : undefined}))).map(i => removeUndefined({name: i.value, attrs: i.attrs, unique: true}))
    const checks: Check[] = buildIndexes(flatAttrs.map(a => ({path: a.path.map(p => p.identifier), index: a.check ? a.check.value?.expression || '' : undefined}))).map(i => removeUndefined({predicate: i.value || '', attrs: i.attrs}))
    return {
        entity: removeEmpty({
            ...entityNamespace,
            name: e.name.identifier,
            kind: undefined, // TODO: use props?
            def: undefined,
            attrs: attrs.map(a => a.attribute),
            pk: pkAttrs.length > 0 ? removeUndefined({
                name: pkAttrs.map(a => a.primaryKey?.value?.identifier).find(isNotUndefined),
                attrs: pkAttrs.map(a => a.path.map(p => p.identifier)),
            }) : undefined,
            indexes: uniques.concat(indexes),
            checks: checks,
            doc: e.note?.note,
            stats: undefined,
            extra: removeUndefined({statement, comment: e.comment?.comment})
        }),
        relations: attrs.flatMap(a => a.relations)
    }
}

function flattenAttributes(attributes: parser.AttributeAstNested[]): parser.AttributeAstNested[] {
    return attributes.flatMap(a => {
        const {attrs, ...values} = a
        return [values].concat(flattenAttributes(attrs || []))
    })
}

function genEntity(e: Entity, relations: Relation[]): string {
    return `${e.name}${genNote(e.doc)}${genCommentExtra(e)}\n` + e.attrs.map(a => genAttribute(a, e, relations.filter(r => r.attrs[0].src[0] === a.name))).join('')
}

function buildIndexes(indexes: {path: AttributePath, index: string | undefined}[]): {value: string | undefined, attrs: AttributePath[]}[] {
    const indexesByName: Record<string, {path: AttributePath, name: string}[]> = groupBy(indexes.map(i => i.index !== undefined ? {path: i.path, name: i.index} : undefined).filter(isNotUndefined), i => i.name)
    const singleIndexes: {value: string | undefined, attrs: AttributePath[]}[] = (indexesByName[''] || []).map(i => ({value: undefined, attrs: [i.path]}))
    const compositeIndexes: {value: string | undefined, attrs: AttributePath[]}[] = Object.entries(indexesByName).filter(([k, _]) => k !== '').map(([value, values]) => ({value, attrs: values.map(v => v.path)}))
    return compositeIndexes.concat(singleIndexes)
}

function buildAttribute(statement: number, a: parser.AttributeAstNested, entity: EntityRef): { attribute: Attribute, relations: Relation[] } {
    const relation = a.relation ? [buildRelationAttribute(statement, a.relation, entity, [a.path.map(p => p.identifier)])] : []
    const nested = a.attrs?.map(aa => buildAttribute(statement, aa, entity))
    return {
        attribute: removeEmpty({
            name: a.path[a.path.length - 1].identifier,
            type: a.type?.identifier || defaultType,
            null: a.nullable ? true : undefined,
            gen: undefined,
            default: a.defaultValue ? buildAttrValue(a.defaultValue) : undefined,
            attrs: nested?.map(n => n.attribute),
            doc: a.note?.note,
            stats: undefined,
            extra: removeUndefined({comment: a.comment?.comment})
        }),
        relations: relation.concat(nested?.flatMap(n => n.relations) || [])
    }
}

function genAttribute(a: Attribute, e: Entity, relations: Relation[], parents: AttributePath = []): string {
    const path = [...parents, a.name]
    const indent = '  '.repeat(path.length)
    const pk = e.pk && e.pk.attrs.some(attr => attributePathSame(attr, path)) ? ' pk' : ''
    const indexes = (e.indexes || []).filter(i => i.attrs.some(attr => attributePathSame(attr, path))).map(i => ` ${i.unique ? 'unique' : 'index'}${i.name ? `=${i.name}` : ''}`).join('')
    const checks = (e.checks || []).filter(i => i.attrs.some(attr => attributePathSame(attr, path))).map(i => ` check${i.predicate ? `=\`${i.predicate}\`` : ''}`).join('')
    const rel = relations.map(r => ' ' + genRelationTarget(r)).join('')
    const nested = a.attrs?.map(aa => genAttribute(aa, e, relations, path)).join('') || ''
    return `${indent}${a.name}${genAttributeType(a)}${pk}${indexes}${checks}${rel}${genNote(a.doc, indent)}${genCommentExtra(a)}\n` + nested
}

function genAttributeType(a: Attribute): string {
    // regex from `Identifier` token: libs/serde-aml/src/parser.ts:7
    const type = a.type && a.type !== defaultType ? ' ' + (a.type.match(/^[a-zA-Z_]\w*$/) ? a.type : '"' + a.type + '"') : ''
    // TODO: enum values
    const defaultValue = a.default !== undefined ? `=${a.default}` : ''
    return type ? type + defaultValue : ''
}

function buildRelationStatement(statement: number, r: parser.RelationAst): Relation {
    return buildRelation(statement, r.kind, buildEntityRef(r.src), r.src.attrs.map(buildAttrPath), r.ref, r.polymorphic, r.note)
}

function buildRelationAttribute(statement: number, r: parser.AttributeRelationAst, srcEntity: EntityRef, srcAttrs: AttributePath[]): Relation {
    return buildRelation(statement, r.kind, srcEntity, srcAttrs, r.ref, r.polymorphic, undefined)
}

function buildRelation(statement: number, kind: parser.RelationKindAst | undefined, srcEntity: EntityRef, srcAttrs: AttributePath[], ref: parser.AttributeRefCompositeAst, polymorphic: parser.RelationPolymorphicAst | undefined, note: parser.NoteAst | undefined): Relation {
    const refAttrs: AttributePath[] = ref.attrs.map(buildAttrPath)
    return removeUndefined({
        name: undefined,
        kind: kind ? buildRelationKind(kind) : undefined,
        origin: undefined,
        src: srcEntity,
        ref: buildEntityRef(ref),
        attrs: zip(srcAttrs, refAttrs).map(([srcAttr, refAttr]) => ({src: srcAttr, ref: refAttr})),
        polymorphic: polymorphic ? {attribute: buildAttrPath(polymorphic.attr), value: buildAttrValue(polymorphic.value)} : undefined,
        doc: note?.note,
        extra: {statement},
    })
}

function genRelation(r: Relation): string {
    return `rel ${getAttributeRef(r.src, r.attrs.map(a => a.src))} ${genRelationTarget(r)}\n`
}

function genRelationTarget(r: Relation): string {
    const poly = r.polymorphic ? `${r.polymorphic.attribute}=${r.polymorphic.value}` : ''
    const [qSrc, qRef] = (r.kind || 'many-to-one').split('-to-')
    const aSecond = qSrc === 'many' ? '>' : '-'
    const aFirst = qRef === 'many' ? '<' : '-'
    return `${aFirst}${poly}${aSecond} ${getAttributeRef(r.ref, r.attrs.map(a => a.ref))}`
}

function getAttributeRef(e: EntityRef, attrs: AttributePath[]) {
    return `${genEntityRef(e)}(${attrs.map(genAttributePath).join(', ')})`
}

function genEntityRef(e: EntityRef): string {
    if (e.database) return [e.database, e.catalog, e.schema, e.entity].join('.')
    if (e.catalog) return [e.catalog, e.schema, e.entity].join('.')
    if (e.schema) return [e.schema, e.entity].join('.')
    return e.entity
}

function genAttributePath(p: AttributePath): string {
    return p.join('.')
}

function buildRelationKind(k: parser.RelationKindAst): RelationKind | undefined {
    switch (k) {
        case '1-1': return 'one-to-one'
        case '1-n': return 'one-to-many'
        case 'n-1': return undefined // 'many-to-one' is default choice
        case 'n-n': return 'many-to-many'
    }
}

function buildEntityRef(e: parser.EntityRefAst): EntityRef {
    return removeUndefined({ database: e.database?.identifier, catalog: e.catalog?.identifier, schema: e.schema?.identifier, entity: e.entity.identifier })
}

function buildAttrPath(a: parser.AttributePathAst): AttributePath {
    return [a.identifier].concat(a.path?.map(p => p.identifier) || [])
}

function buildAttrValue(a: parser.AttributeValueAst): AttributeValue {
    if ('null' in a) {
        return null
    } else if ('value' in a) {
        return a.value
    } else if ('flag' in a) {
        return a.flag
    } else if ('identifier' in a) {
        return a.identifier
    } else {
        return '`' + a.expression + '`'
    }
}

function genNote(doc: string | undefined, indent: string = ''): string {
    if (!doc) return ''
    if (doc.indexOf('\n') === -1) return ' | ' + doc
    return ' |||\n' + doc.split('\n').map(l => indent + '  ' + l + '\n').join('') + indent + '|||'
}

function genCommentExtra(v: {extra?: Extra | undefined}): string {
    return v.extra && 'comment' in v.extra ? genComment(v.extra.comment) : ''
}

function genComment(comment: string | undefined): string {
    return comment ? ' # ' + comment : ''
}
