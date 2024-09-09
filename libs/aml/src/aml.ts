import {
    groupBy,
    isNever,
    isNotUndefined,
    mapEntriesDeep,
    partition,
    removeEmpty,
    removeUndefined,
    zip
} from "@azimutt/utils";
import {
    Attribute,
    AttributePath,
    attributePathSame,
    AttributeType,
    AttributeValue,
    Check,
    Database,
    Entity,
    EntityRef,
    Extra,
    Index,
    Namespace,
    ParserError,
    ParserResult,
    Relation,
    RelationKind,
    Type
} from "@azimutt/models";
import {version} from "../package.json"
import {
    AmlAst,
    AttributeAstNested,
    AttributePathAst,
    AttributeRefCompositeAst,
    AttributeRelationAst,
    AttributeValueAst,
    EntityAst,
    EntityRefAst,
    ExtraAst,
    isTokenInfo,
    NamespaceAst,
    RelationAst,
    RelationKindAst,
    RelationPolymorphicAst,
    TypeAst,
    TypeContentAst
} from "./ast";
import {parseAmlAst} from "./parser";

export function parseAml(content: string): ParserResult<Database> {
    const start = Date.now()
    return parseAmlAst(content + '\n').flatMap(ast => {
        const parsed = Date.now()
        const errors: ParserError[] = []
        mapEntriesDeep(ast, (path, value) => {
            if (isTokenInfo(value) && value.issues) {
                value.issues.forEach(i => errors.push({...i, offset: value.offset, position: value.position}))
            }
            return value
        })
        const db = buildDatabase(ast, start, parsed)
        return new ParserResult(db, errors)
    })
}

export function generateAml(database: Database): string {
    return genDatabase(database)
}

// private functions 👇️ (some may be exported for tests)

const defaultType = 'unknown'

function buildDatabase(ast: AmlAst, start: number, parsed: number): Database {
    const db: Database = {entities: [], relations: [], types: []}
    let namespace: Namespace = {}
    ast.filter(s => s !== undefined && s.statement !== 'Empty').forEach((stmt, i) => { // `s` can be undefined on invalid input :/
        const index = i + 1
        if (stmt.statement === 'Namespace') {
            namespace = buildNamespace(index, stmt, namespace)
        } else if (stmt.statement === 'Entity') {
            const {entity, relations, types} = buildEntity(index, stmt, namespace)
            db.entities?.push(entity) // TODO: check if entity already exists
            relations.forEach(r => db.relations?.push(r))
            types.forEach(t => db.types?.push(t))
        } else if (stmt.statement === 'Relation') {
            const rel = buildRelationStatement(index, stmt)
            rel && db.relations?.push(rel) // TODO: check if relation already exists
        } else if (stmt.statement === 'Type') {
            db.types?.push(buildType(index, stmt, namespace)) // TODO: check if relation already exists
        } else {
            // Empty: do nothing
        }
    })
    const done = Date.now()
    const extra = {source: `AML parser ${version}`, parsedAt: new Date().toISOString(), parsingMs: parsed - start, formattingMs: done - parsed}
    return removeEmpty({...db, extra})
}

function genDatabase(database: Database): string {
    const [entityRels, aloneRels] = partition(database.relations || [], r => {
        const statement = r.extra && 'statement' in r.extra && r.extra.statement
        return statement ? !!database.entities?.find(e => e.extra && 'statement' in e.extra && e.extra.statement === statement) : false
    })
    const [entityTypes, aloneTypes] = partition(database.types || [], t => {
        const statement = t.extra && 'statement' in t.extra && t.extra.statement
        return statement ? !!database.entities?.find(e => e.extra && 'statement' in e.extra && e.extra.statement === statement) : false
    })
    const entities = (database.entities || []).map((e, i) => {
        const statement = e.extra && 'statement' in e.extra && e.extra.statement
        const rels = statement ? entityRels.filter(r => r.extra && 'statement' in r.extra && r.extra.statement === statement) : []
        const types = statement ? entityTypes.filter(t => t.extra && 'statement' in t.extra && t.extra.statement === statement) : []
        return {index: statement || i, aml: genEntity(e, rels, types)}
    })
    const entityCount = entities.length
    const relations = aloneRels.map((r, i) => {
        const statement = r.extra && 'statement' in r.extra && r.extra.statement
        return {index: statement || entityCount + i, aml: genRelation(r)}
    })
    const relationsCount = relations.length
    const types = aloneTypes.map((t, i) => {
        const statement = t.extra && 'statement' in t.extra && t.extra.statement
        return {index: statement || entityCount + relationsCount + i, aml: genType(t)}
    })
    return entities.concat(relations, types).sort((a, b) => a.index - b.index).map(a => a.aml).join('\n') || ''
}

function buildNamespace(statement: number, n: NamespaceAst, current: Namespace): Namespace {
    const schema = n.schema.value
    const catalog = n.catalog?.value || current.catalog
    const database = n.database?.value || current.database
    return {schema, catalog, database}
}

function buildEntity(statement: number, e: EntityAst, namespace: Namespace): { entity: Entity, relations: Relation[], types: Type[] } {
    const astNamespace = removeUndefined({schema: e.schema?.value, catalog: e.catalog?.value, database: e.database?.value})
    const entityNamespace = {...namespace, ...astNamespace}
    const validAttrs = (e.attrs || []).filter(a => !a.path.some(p => p === undefined)) // `path` can be `[undefined]` on invalid input :/
    const attrs = validAttrs.map(a => buildAttribute(statement, a, {...entityNamespace, entity: e.name.value}))
    const flatAttrs = flattenAttributes(validAttrs).filter(a => !a.path.some(p => p === undefined)) // nested attributes can have `path` be `[undefined]` on invalid input :/
    const pkAttrs = flatAttrs.filter(a => a.primaryKey)
    const indexes: Index[] = buildIndexes(flatAttrs.map(a => ({path: a.path.map(p => p.value), index: a.index ? a.index.name?.value || '' : undefined}))).map(i => removeUndefined({name: i.value, attrs: i.attrs}))
    const uniques: Index[] = buildIndexes(flatAttrs.map(a => ({path: a.path.map(p => p.value), index: a.unique ? a.unique.name?.value || '' : undefined}))).map(i => removeUndefined({name: i.value, attrs: i.attrs, unique: true}))
    const checks: Check[] = buildIndexes(flatAttrs.map(a => ({path: a.path.map(p => p.value), index: a.check ? a.check.definition?.value || '' : undefined}))).map(i => removeUndefined({predicate: i.value || '', attrs: i.attrs}))
    return {
        entity: removeEmpty({
            ...entityNamespace,
            name: e.name.value,
            kind: e.view ? 'view' as const : undefined, // TODO: use props also
            def: undefined,
            attrs: attrs.map(a => a.attribute),
            pk: pkAttrs.length > 0 ? removeUndefined({
                name: pkAttrs.map(a => a.primaryKey?.name?.value).find(isNotUndefined),
                attrs: pkAttrs.map(a => a.path.map(p => p.value)),
            }) : undefined,
            indexes: uniques.concat(indexes),
            checks: checks,
            doc: e.doc?.value,
            stats: undefined,
            extra: removeEmpty({statement, comment: e.comment?.value})
        }),
        relations: attrs.flatMap(a => a.relations),
        types: attrs.flatMap(a => a.types),
    }
}

function flattenAttributes(attributes: AttributeAstNested[]): AttributeAstNested[] {
    return attributes.flatMap(a => {
        const {attrs, ...values} = a
        return [values].concat(flattenAttributes(attrs || []))
    })
}

function genEntity(e: Entity, relations: Relation[], types: Type[]): string {
    const entity = `${e.name}${e.kind === 'view' ? '*' : ''}${genNote(e.doc)}${genCommentExtra(e)}\n`
    return entity + e.attrs?.map(a => genAttribute(a, e, relations.filter(r => r.attrs[0].src[0] === a.name), types)).join('')
}

function buildIndexes(indexes: {path: AttributePath, index: string | undefined}[]): {value: string | undefined, attrs: AttributePath[]}[] {
    const indexesByName: Record<string, {path: AttributePath, name: string}[]> = groupBy(indexes.map(i => i.index !== undefined ? {path: i.path, name: i.index} : undefined).filter(isNotUndefined), i => i.name)
    const singleIndexes: {value: string | undefined, attrs: AttributePath[]}[] = (indexesByName[''] || []).map(i => ({value: undefined, attrs: [i.path]}))
    const compositeIndexes: {value: string | undefined, attrs: AttributePath[]}[] = Object.entries(indexesByName).filter(([k, _]) => k !== '').map(([value, values]) => ({value, attrs: values.map(v => v.path)}))
    return compositeIndexes.concat(singleIndexes)
}

function buildAttribute(statement: number, a: AttributeAstNested, entity: EntityRef): { attribute: Attribute, relations: Relation[], types: Type[] } {
    const {entity: _, ...namespace} = entity
    const typeExt = a.enumValues && a.enumValues.length <= 2 && a.enumValues.every(v => v.token === 'Integer') ? '(' + a.enumValues.map(stringifyAttrValue).join(',') + ')' : ''
    const enumType: Type[] = a.type && a.enumValues && !typeExt ? [{...namespace, name: a.type.value, values: a.enumValues.map(stringifyAttrValue), extra: {statement, line: a.enumValues[0].position.start.line}}] : []
    const relation: Relation[] = a.relation ? [buildRelationAttribute(statement, a.relation, entity, [a.path.map(p => p.value)])].filter(isNotUndefined) : []
    const validAttrs = (a.attrs || []).filter(aa => !aa.path.some(p => p === undefined)) // `path` can be `[undefined]` on invalid input :/
    const nested = validAttrs.map(aa => buildAttribute(statement, aa, entity))
    return {
        attribute: removeEmpty({
            name: a.path[a.path.length - 1].value,
            type: buildAttributeType(a, typeExt),
            null: a.nullable ? true : undefined,
            gen: undefined,
            default: a.defaultValue ? buildAttrValue(a.defaultValue) : undefined,
            attrs: nested.map(n => n.attribute),
            doc: a.doc?.value,
            stats: undefined,
            extra: removeEmpty({comment: a.comment?.value})
        }),
        relations: relation.concat(nested.flatMap(n => n.relations)),
        types: enumType.concat(nested.flatMap(n => n.types)),
    }
}

function genAttribute(a: Attribute, e: Entity, relations: Relation[], types: Type[], parents: AttributePath = []): string {
    const path = [...parents, a.name]
    const indent = '  '.repeat(path.length)
    const nested = a.attrs?.map(aa => genAttribute(aa, e, relations, types, path)).join('') || ''
    return indent + genAttributeInner(a, e, relations, types, path, indent) + '\n' + nested
}

function genAttributeInner(a: Attribute, e: Entity, relations: Relation[], types: Type[], path: AttributePath, indent: string): string {
    const pk = e.pk && e.pk.attrs.some(attr => attributePathSame(attr, path)) ? ' pk' : ''
    const indexes = (e.indexes || []).filter(i => i.attrs.some(attr => attributePathSame(attr, path))).map(i => ` ${i.unique ? 'unique' : 'index'}${i.name ? `=${i.name}` : ''}`).join('')
    const checks = (e.checks || []).filter(i => i.attrs.some(attr => attributePathSame(attr, path))).map(i => ` check${i.predicate ? `=\`${i.predicate}\`` : ''}`).join('')
    const rel = relations.map(r => ' ' + genRelationTarget(r)).join('')
    return `${a.name}${genAttributeType(a, types)}${pk}${indexes}${checks}${rel}${genNote(a.doc, indent)}${genCommentExtra(a)}`
}

function buildAttributeType(a: AttributeAstNested, ext: string): AttributeType {
    return a.type ? a.type.value + ext : defaultType
}

function genAttributeType(a: Attribute, types: Type[]): string {
    // regex from `Identifier` token to know if it should be escaped or not (cf libs/aml/src/parser.ts:7)
    const typeName = a.type && a.type !== defaultType ? ' ' + (a.type.match(/^[a-zA-Z_]\w*$/) ? a.type : '"' + a.type + '"') : ''
    const enumType = types.find(t => t.name === a.type && t.values)
    const enumValues = enumType ? '(' + enumType.values?.join(', ') + ')' : ''
    const defaultValue = a.default !== undefined ? `=${a.default}` : ''
    return typeName ? typeName + enumValues + defaultValue : ''
}

function buildRelationStatement(statement: number, r: RelationAst): Relation | undefined {
    const entitySrc = buildEntityRef(r.src)
    return entitySrc ? buildRelation(statement, r.kind, entitySrc, r.src.attrs.map(buildAttrPath), r.ref, r.polymorphic, r) : undefined
}

function buildRelationAttribute(statement: number, r: AttributeRelationAst, srcEntity: EntityRef, srcAttrs: AttributePath[]): Relation | undefined {
    return buildRelation(statement, r.kind, srcEntity, srcAttrs, r.ref, r.polymorphic, undefined)
}

function buildRelation(statement: number, kind: RelationKindAst | undefined, srcEntity: EntityRef, srcAttrs: AttributePath[], ref: AttributeRefCompositeAst, polymorphic: RelationPolymorphicAst | undefined, extra: ExtraAst | undefined): Relation | undefined {
    if (!ref || !ref.attrs || ref.attrs.some(a => a.value === undefined)) return undefined // `ref` can be undefined or with undefined attrs on invalid input :/ TODO: report an error instead of just ignoring?
    const refAttrs: AttributePath[] = ref.attrs.map(buildAttrPath)
    const entityRef = buildEntityRef(ref)
    return entityRef ? removeUndefined({
        name: undefined,
        kind: kind ? buildRelationKind(kind) : undefined,
        origin: undefined,
        src: srcEntity,
        ref: entityRef,
        attrs: zip(srcAttrs, refAttrs).map(([srcAttr, refAttr]) => ({src: srcAttr, ref: refAttr})),
        polymorphic: polymorphic ? {attribute: buildAttrPath(polymorphic.attr), value: buildAttrValue(polymorphic.value)} : undefined,
        doc: extra?.doc?.value,
        extra: removeEmpty({statement, comment: extra?.comment?.value}),
    }) : undefined
}

function genRelation(r: Relation): string {
    return `rel ${genAttributeRef(r.src, r.attrs.map(a => a.src))} ${genRelationTarget(r)}${genNote(r.doc)}${genCommentExtra(r)}\n`
}

function genRelationTarget(r: Relation): string {
    const poly = r.polymorphic ? `${r.polymorphic.attribute}=${r.polymorphic.value}` : ''
    const [qSrc, qRef] = (r.kind || 'many-to-one').split('-to-')
    const aSecond = qSrc === 'many' ? '>' : '-'
    const aFirst = qRef === 'many' ? '<' : '-'
    return `${aFirst}${poly}${aSecond} ${genAttributeRef(r.ref, r.attrs.map(a => a.ref))}`
}

function buildType(statement: number, t: TypeAst, namespace: Namespace): Type {
    const astNamespace = removeUndefined({schema: t.schema?.value, catalog: t.catalog?.value, database: t.database?.value})
    const typeNamespace = {...namespace, ...astNamespace}
    const content = t.content ? buildTypeContent(statement, t.content, {...typeNamespace, entity: t.name.value}) : {}
    return removeUndefined({...typeNamespace, name: t.name.value, ...content, doc: t.doc?.value, extra: removeEmpty({statement, line: t.name.position.start.line, comment: t.comment?.value})})
}

function buildTypeContent(statement: number, t: TypeContentAst, entity: EntityRef): {definition?: string, values?: string[], attrs?: Attribute[]} {
    if (t.kind === 'alias') return {definition: t.name.value}
    if (t.kind === 'enum') return {values: t.values.map(stringifyAttrValue)}
    if (t.kind === 'struct') return {attrs: t.attrs.map(a => buildAttribute(statement, a, entity).attribute)}
    if (t.kind === 'custom') return {definition: t.definition.value}
    return isNever(t)
}

function genType(t: Type): string {
    return `type ${genEntityRef({...t, entity: t.name})}${genTypeContent(t)}${genNote(t.doc)}${genCommentExtra(t)}\n`
}

function genTypeContent(t: Type): string {
    if (t.definition && t.definition.match(/[ (]/)) return ' `' + t.definition + '`'
    if (t.definition) return ' ' + t.definition
    if (t.values) return ' (' + t.values.join(', ') + ')'
    if (t.attrs) return ' {' + t.attrs.map(a => genAttributeInner(a, {name: t.name}, [], [], [a.name], '')).join(', ') + '}'
    return ''
}

export function genAttributeRef(e: EntityRef, attrs: AttributePath[]): string {
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

function buildRelationKind(k: RelationKindAst): RelationKind | undefined {
    switch (k) {
        case '1-1': return 'one-to-one'
        case '1-n': return 'one-to-many'
        case 'n-1': return undefined // 'many-to-one' is default choice
        case 'n-n': return 'many-to-many'
    }
}

function buildEntityRef(e: EntityRefAst): EntityRef | undefined {
    if (!e.entity) return undefined // on bad input the parser can build bad ast (no entity) :/ TODO: report an error instead of just ignoring?
    return removeUndefined({ database: e.database?.value, catalog: e.catalog?.value, schema: e.schema?.value, entity: e.entity.value })
}

function buildAttrPath(a: AttributePathAst): AttributePath {
    return [a.value].concat(a.path?.map(p => p.value) || [])
}

function buildAttrValue(v: AttributeValueAst): AttributeValue {
    if (v.token === 'Null') return null
    if (v.token === 'Decimal') return v.value
    if (v.token === 'Integer') return v.value
    if (v.token === 'Boolean') return v.value
    if (v.token === 'Expression') return '`' + v.value + '`'
    if (v.token === 'Identifier') return v.value
    return isNever(v)
}

function stringifyAttrValue(v: AttributeValueAst): string {
    if (v.token === 'Null') return 'null'
    if (v.token === 'Decimal') return v.value.toString()
    if (v.token === 'Integer') return v.value.toString()
    if (v.token === 'Boolean') return v.value ? 'true' : 'false'
    if (v.token === 'Expression') return v.value
    if (v.token === 'Identifier') return v.value
    return isNever(v)
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
