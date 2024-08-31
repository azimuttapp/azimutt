import {isNotUndefined, partition, removeEmpty, removeUndefined, zip} from "@azimutt/utils";
import {
    Attribute,
    AttributePath,
    AttributeValue,
    Database,
    Entity,
    EntityRef,
    Namespace,
    ParserResult,
    Relation,
    RelationKind
} from "@azimutt/models";
import * as parser from "./parser";
import {version} from "./version";

export function parse(content: string): ParserResult<Database> {
    const start = Date.now()
    return parser.parse(content).map(ast => buildDatabase(ast, start, Date.now()))
}

export function generate(database: Database): string {
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
    const pkAttrs = e.attrs.filter(a => a.primaryKey).map(a => [a.name.identifier]) // TODO: handle nested attrs
    const attrs = e.attrs.map(a => buildAttribute(statement, a, {...entityNamespace, entity: e.name.identifier})) // TODO: handle nested attrs
    const relations: Relation[] = attrs.map(a => a.relation).filter(isNotUndefined)
    return {
        entity: removeUndefined({
            ...entityNamespace,
            name: e.name.identifier,
            kind: undefined, // TODO: use props?
            def: undefined,
            attrs: attrs.map(a => a.attribute),
            pk: pkAttrs.length > 0 ? {attrs: pkAttrs} : undefined,
            indexes: undefined, // TODO
            checks: undefined, // TODO
            doc: e.note?.note,
            stats: undefined,
            extra: {statement},
        }),
        relations
    }
}

function genEntity(e: Entity, relations: Relation[]): string {
    const note = e.doc ? ' | ' + e.doc : ''
    const comment = e.extra && 'comment' in e.extra ? ' # ' + e.extra.comment : ''
    return `${e.name}${note}${comment}\n` + e.attrs.map(a => genAttribute(a, e, relations.filter(r => r.attrs[0].src[0] === a.name))).join('')
}

function buildAttribute(statement: number, a: parser.AttributeAst, entity: EntityRef): { attribute: Attribute, relation?: Relation } {
    const relation = a.relation ? buildRelationAttribute(statement, a.relation, entity, [[a.name.identifier]]) : undefined // TODO: handle nested attrs
    return {
        attribute: removeEmpty({
            name: a.name.identifier,
            type: a.type?.identifier || defaultType,
            null: a.nullable ? true : undefined,
            gen: undefined,
            default: a.defaultValue ? buildAttrValue(a.defaultValue) : undefined,
            attrs: undefined, // TODO z.lazy(() => Attribute.array().optional()),
            doc: a.note?.note,
            stats: undefined,
            extra: removeUndefined({comment: a.comment?.comment})
        }),
        relation
    }
}

function genAttribute(a: Attribute, e: Entity, relations: Relation[]): string {
    const type = a.type && a.type !== defaultType ? ' ' + a.type : ''
    const pk = e.pk && e.pk.attrs.some(attr => attr.length === 1 && attr[0] === a.name) ? ' pk' : '' // TODO: handle nested attrs
    const rel = relations.map(r => ' ' + genRelationTarget(r)).join('')
    const note = a.doc ? ' | ' + a.doc : ''
    const comment = a.extra && 'comment' in a.extra ? ' # ' + a.extra.comment : ''
    return `  ${a.name}${type}${pk}${rel}${note}${comment}\n`
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
    return `rel ${getAttributeRef(r.src, r.attrs.map(a => a.src))} ${genRelationTarget(r)}`
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
        return a.expression
    }
}
