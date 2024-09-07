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
    parseAmlAst,
    RelationAst,
    RelationKindAst,
    RelationPolymorphicAst,
    TypeAst,
    TypeContentAst
} from "./parser";

export function parseAml(content: string): ParserResult<Database> {
    const start = Date.now()
    return parseAmlAst(content + '\n').flatMap(ast => {
        const db = buildDatabase(ast, start, Date.now())
        const warnings: ParserError[] = []
        mapEntriesDeep(ast, (path, value) => {
            if (path[path.length - 1] === 'warning' && isTokenInfo(value) && value.message) {
                warnings.push({
                    name: 'warning',
                    message: value.message.message,
                    position: {offset: value.offset, line: value.line, column: value.column}
                })
            }
        })
        return new ParserResult(db, undefined, warnings)
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
    ast.filter(s => s.statement !== 'Empty').forEach((stmt, i) => {
        const index = i + 1
        if (stmt.statement === 'Namespace') {
            namespace = buildNamespace(index, stmt, namespace)
        } else if (stmt.statement === 'Entity') {
            const {entity, relations, types} = buildEntity(index, stmt, namespace)
            db.entities?.push(entity) // TODO: check if entity already exists
            relations.forEach(r => db.relations?.push(r))
            types.forEach(t => db.types?.push(t))
        } else if (stmt.statement === 'Relation') {
            db.relations?.push(buildRelationStatement(index, stmt)) // TODO: check if relation already exists
        } else if (stmt.statement === 'Type') {
            db.types?.push(buildType(index, stmt, namespace)) // TODO: check if relation already exists
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
    const schema = n.schema.identifier
    const catalog = n.catalog?.identifier || current.catalog
    const database = n.database?.identifier || current.database
    return {schema, catalog, database}
}

function buildEntity(statement: number, e: EntityAst, namespace: Namespace): { entity: Entity, relations: Relation[], types: Type[] } {
    const astNamespace = removeUndefined({schema: e.schema?.identifier, catalog: e.catalog?.identifier, database: e.database?.identifier})
    const entityNamespace = {...namespace, ...astNamespace}
    const attrs = (e.attrs || []).map(a => buildAttribute(statement, a, {...entityNamespace, entity: e.name.identifier}))
    const flatAttrs = flattenAttributes(e.attrs || [])
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
            extra: removeEmpty({statement, comment: e.comment?.comment})
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
    return `${e.name}${genNote(e.doc)}${genCommentExtra(e)}\n` + e.attrs?.map(a => genAttribute(a, e, relations.filter(r => r.attrs[0].src[0] === a.name), types)).join('')
}

function buildIndexes(indexes: {path: AttributePath, index: string | undefined}[]): {value: string | undefined, attrs: AttributePath[]}[] {
    const indexesByName: Record<string, {path: AttributePath, name: string}[]> = groupBy(indexes.map(i => i.index !== undefined ? {path: i.path, name: i.index} : undefined).filter(isNotUndefined), i => i.name)
    const singleIndexes: {value: string | undefined, attrs: AttributePath[]}[] = (indexesByName[''] || []).map(i => ({value: undefined, attrs: [i.path]}))
    const compositeIndexes: {value: string | undefined, attrs: AttributePath[]}[] = Object.entries(indexesByName).filter(([k, _]) => k !== '').map(([value, values]) => ({value, attrs: values.map(v => v.path)}))
    return compositeIndexes.concat(singleIndexes)
}

function buildAttribute(statement: number, a: AttributeAstNested, entity: EntityRef): { attribute: Attribute, relations: Relation[], types: Type[] } {
    const {entity: _, ...namespace} = entity
    const typeExt = a.enumValues && a.enumValues.length <= 2 && a.enumValues.every(v => v.parser.token === 'Integer') ? '(' + a.enumValues.map(stringifyAttrValue).join(',') + ')' : ''
    const enumType: Type[] = a.type && a.enumValues && !typeExt ? [{...namespace, name: a.type.identifier, values: a.enumValues.map(stringifyAttrValue), extra: {statement, line: a.enumValues[0].parser.line[0]}}] : []
    const relation: Relation[] = a.relation ? [buildRelationAttribute(statement, a.relation, entity, [a.path.map(p => p.identifier)])] : []
    const nested = a.attrs?.map(aa => buildAttribute(statement, aa, entity)) || []
    return {
        attribute: removeEmpty({
            name: a.path[a.path.length - 1].identifier,
            type: buildAttributeType(a, typeExt),
            null: a.nullable ? true : undefined,
            gen: undefined,
            default: a.defaultValue ? buildAttrValue(a.defaultValue) : undefined,
            attrs: nested.map(n => n.attribute),
            doc: a.note?.note,
            stats: undefined,
            extra: removeEmpty({comment: a.comment?.comment})
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
    return a.type ? a.type.identifier + ext : defaultType
}

function genAttributeType(a: Attribute, types: Type[]): string {
    // regex from `Identifier` token to know if it should be escaped or not (cf libs/aml/src/parser.ts:7)
    const typeName = a.type && a.type !== defaultType ? ' ' + (a.type.match(/^[a-zA-Z_]\w*$/) ? a.type : '"' + a.type + '"') : ''
    const enumType = types.find(t => t.name === a.type && t.values)
    const enumValues = enumType ? '(' + enumType.values?.join(', ') + ')' : ''
    const defaultValue = a.default !== undefined ? `=${a.default}` : ''
    return typeName ? typeName + enumValues + defaultValue : ''
}

function buildRelationStatement(statement: number, r: RelationAst): Relation {
    return buildRelation(statement, r.kind, buildEntityRef(r.src), r.src.attrs.map(buildAttrPath), r.ref, r.polymorphic, r)
}

function buildRelationAttribute(statement: number, r: AttributeRelationAst, srcEntity: EntityRef, srcAttrs: AttributePath[]): Relation {
    return buildRelation(statement, r.kind, srcEntity, srcAttrs, r.ref, r.polymorphic, undefined)
}

function buildRelation(statement: number, kind: RelationKindAst | undefined, srcEntity: EntityRef, srcAttrs: AttributePath[], ref: AttributeRefCompositeAst, polymorphic: RelationPolymorphicAst | undefined, extra: ExtraAst | undefined): Relation {
    const refAttrs: AttributePath[] = ref.attrs.map(buildAttrPath)
    return removeUndefined({
        name: undefined,
        kind: kind ? buildRelationKind(kind) : undefined,
        origin: undefined,
        src: srcEntity,
        ref: buildEntityRef(ref),
        attrs: zip(srcAttrs, refAttrs).map(([srcAttr, refAttr]) => ({src: srcAttr, ref: refAttr})),
        polymorphic: polymorphic ? {attribute: buildAttrPath(polymorphic.attr), value: buildAttrValue(polymorphic.value)} : undefined,
        doc: extra?.note?.note,
        extra: removeEmpty({statement, comment: extra?.comment?.comment}),
    })
}

function genRelation(r: Relation): string {
    return `rel ${getAttributeRef(r.src, r.attrs.map(a => a.src))} ${genRelationTarget(r)}${genNote(r.doc)}${genCommentExtra(r)}\n`
}

function genRelationTarget(r: Relation): string {
    const poly = r.polymorphic ? `${r.polymorphic.attribute}=${r.polymorphic.value}` : ''
    const [qSrc, qRef] = (r.kind || 'many-to-one').split('-to-')
    const aSecond = qSrc === 'many' ? '>' : '-'
    const aFirst = qRef === 'many' ? '<' : '-'
    return `${aFirst}${poly}${aSecond} ${getAttributeRef(r.ref, r.attrs.map(a => a.ref))}`
}

function buildType(statement: number, t: TypeAst, namespace: Namespace): Type {
    const astNamespace = removeUndefined({schema: t.schema?.identifier, catalog: t.catalog?.identifier, database: t.database?.identifier})
    const typeNamespace = {...namespace, ...astNamespace}
    const content = t.content ? buildTypeContent(statement, t.content, {...typeNamespace, entity: t.name.identifier}) : {}
    return removeUndefined({...typeNamespace, name: t.name.identifier, ...content, doc: t.note?.note, extra: removeEmpty({statement, line: t.name.parser.line[0], comment: t.comment?.comment})})
}

function buildTypeContent(statement: number, t: TypeContentAst, entity: EntityRef): {definition?: string, values?: string[], attrs?: Attribute[]} {
    if (t.kind === 'alias') return {definition: t.name.identifier}
    if (t.kind === 'enum') return {values: t.values.map(stringifyAttrValue)}
    if (t.kind === 'struct') return {attrs: t.attrs.map(a => buildAttribute(statement, a, entity).attribute)}
    if (t.kind === 'custom') return {definition: t.definition.expression}
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

function buildRelationKind(k: RelationKindAst): RelationKind | undefined {
    switch (k) {
        case '1-1': return 'one-to-one'
        case '1-n': return 'one-to-many'
        case 'n-1': return undefined // 'many-to-one' is default choice
        case 'n-n': return 'many-to-many'
    }
}

function buildEntityRef(e: EntityRefAst): EntityRef {
    return removeUndefined({ database: e.database?.identifier, catalog: e.catalog?.identifier, schema: e.schema?.identifier, entity: e.entity.identifier })
}

function buildAttrPath(a: AttributePathAst): AttributePath {
    return [a.identifier].concat(a.path?.map(p => p.identifier) || [])
}

function buildAttrValue(v: AttributeValueAst): AttributeValue {
    if ('null' in v) return null
    if ('value' in v) return v.value
    if ('flag' in v) return v.flag
    if ('identifier' in v) return v.identifier
    if ('expression' in v) return '`' + v.expression + '`'
    return isNever(v)
}

function stringifyAttrValue(v: AttributeValueAst): string {
    if ('null' in v) return 'null'
    if ('value' in v) return v.value.toString()
    if ('flag' in v) return v.flag.toString()
    if ('identifier' in v) return v.identifier
    if ('expression' in v) return v.expression
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
