import {groupBy, isNever, isNotUndefined, removeEmpty, removeUndefined, zip} from "@azimutt/utils";
import {
    Attribute,
    AttributePath,
    AttributeType,
    AttributeValue,
    Check,
    Database,
    Entity,
    EntityRef,
    entityRefSame,
    entityToId,
    entityToRef,
    Extra,
    Index,
    legacyColumnTypeUnknown,
    mergePositions,
    Namespace,
    ParserError,
    Relation,
    RelationKind,
    relationRefSame,
    relationToId,
    relationToRef,
    TokenPosition,
    Type,
    typeRefSame,
    typeToId,
    typeToRef
} from "@azimutt/models";
import packageJson from "../package.json";
import {
    AmlAst,
    AttributeAstNested,
    AttributePathAst,
    AttributeRefCompositeAst,
    AttributeRelationAst,
    AttributeValueAst,
    EntityRefAst,
    EntityStatement,
    ExtraAst,
    NamespaceStatement,
    PropertiesAst,
    PropertyValue,
    PropertyValueAst,
    PropertyValueBasic,
    RelationKindAst,
    RelationPolymorphicAst,
    RelationStatement,
    TypeContentAst,
    TypeStatement
} from "./amlAst";
import {duplicated} from "./errors";

export function buildDatabase(ast: AmlAst, start: number, parsed: number): {db: Database, errors: ParserError[]} {
    const db: Database = {entities: [], relations: [], types: []}
    const errors: ParserError[] = []
    const statements = ast.filter(s => s.statement !== 'Empty')
    const entityRelations = buildTypesAndEntities(db, errors, statements)
    buildRelations(db, errors, statements, entityRelations) // all entities need to be built to perform some relation checks
    const comments: {line: number, comment: string}[] = []
    ast.filter(s => s.statement === 'Empty').forEach(stmt => {
        if (stmt.comment) comments.push({line: stmt.comment.position.start.line, comment: stmt.comment.value})
    })
    const done = Date.now()
    const extra = removeEmpty({
        source: `AML parser <${packageJson.version}>`,
        createdAt: new Date().toISOString(),
        creationTimeMs: done - start,
        parsingTimeMs: parsed - start,
        formattingTimeMs: done - parsed,
        comments
    })
    return {db: removeEmpty({
        entities: db.entities?.sort((a, b) => a.extra?.line && b.extra?.line ? a.extra.line - b.extra.line : a.name.toLowerCase().localeCompare(b.name.toLowerCase())),
        relations: db.relations?.sort((a, b) => a.extra?.line && b.extra?.line ? a.extra.line - b.extra.line : a.src.entity.toLowerCase().localeCompare(b.src.entity.toLowerCase())),
        types: db.types?.sort((a, b) => a.extra?.line && b.extra?.line ? a.extra.line - b.extra.line : a.name.toLowerCase().localeCompare(b.name.toLowerCase())),
        extra
    }), errors}
}

function buildTypesAndEntities(db: Database, errors: ParserError[], ast: AmlAst): InlineRelation[] {
    let namespace: Namespace = {}
    const relations: InlineRelation[] = []
    ast.forEach((stmt, i) => {
        const index = i + 1
        if (stmt.statement === 'Namespace') {
            namespace = buildNamespace(index, stmt)
        } else if (stmt.statement === 'Type') {
            const type = buildType(namespace, index, stmt)
            addType(db, errors, type, mergePositions([stmt.database, stmt.catalog, stmt.schema, stmt.name]))
        } else if (stmt.statement === 'Entity') {
            const res = buildEntity(namespace, index, stmt)
            const prev = db.entities?.find(e => entityRefSame(entityToRef(e), entityToRef(res.entity)))
            if (prev) {
                errors.push(duplicated(
                    `Entity ${entityToId(res.entity)}`,
                    prev.extra?.line ? prev.extra.line : undefined,
                    mergePositions([stmt.database, stmt.catalog, stmt.schema, stmt.name])
                ))
                // TODO: merge entities
            } else {
                db.entities?.push(res.entity)
            }
            res.relations.forEach(r => relations.push(r))
            res.types.forEach(({type, position}) => addType(db, errors, type, position))
        } else {
            // ignore other statements, types are already built, relations will be built after
        }
    })
    return relations
}

function buildRelations(db: Database, errors: ParserError[], ast: AmlAst, attrRelations: InlineRelation[]): void {
    let namespace: Namespace = {}
    attrRelations.forEach(r => addRelation(
        db,
        errors,
        buildRelationAttribute(db.entities || [], r.namespace, r.statement, r.entity, r.attrs, r.ref),
        mergePositions([r.ref.ref.database, r.ref.ref.catalog, r.ref.ref.schema, r.ref.ref.entity, ...r.ref.ref.attrs])
    ))
    ast.forEach((stmt, i) => {
        const index = i + 1
        if (stmt.statement === 'Namespace') {
            namespace = buildNamespace(index, stmt)
        } else if (stmt.statement === 'Relation') {
            addRelation(
                db,
                errors,
                buildRelationStatement(db.entities || [], namespace, index, stmt),
                mergePositions([stmt.src.database, stmt.src.catalog, stmt.src.schema, stmt.src.entity, ...(stmt.ref?.attrs || [])])
            )
        } else {
            // last to be built, types & relations are already built
        }
    })
}

function addRelation(db: Database, errors: ParserError[], relation: Relation | undefined, position: TokenPosition) {
    // TODO: relation src & ref should have exist, otherwise warning
    if (relation) {
        const prev = db.relations?.find(r => relationRefSame(relationToRef(r), relationToRef(relation)))
        if (prev && !prev.polymorphic) {
            errors.push(duplicated(`Relation ${relationToId(relation)}`, prev.extra?.line ? prev.extra.line : undefined, position))
            // TODO: merge relations (extra)? add duplicates?
        } else {
            db.relations?.push(relation)
        }
    } else {
        // TODO: warning: ignored relation (should return the cause)
    }
}

function addType(db: Database, errors: ParserError[], type: Type, position: TokenPosition): void {
    const prev = db.types?.find(t => typeRefSame(typeToRef(t), typeToRef(type)))
    if (prev) {
        errors.push(duplicated(`Type ${typeToId(type)}`, prev.extra?.line ? prev.extra.line : undefined, position))
        // TODO: merge types? add duplicates?
    } else {
        db.types?.push(type)
    }
}

function buildNamespace(statement: number, n: NamespaceStatement): Namespace {
    return removeUndefined({schema: n.schema?.value, catalog: n.catalog?.value, database: n.database?.value})
}

function buildEntity(namespace: Namespace, statement: number, e: EntityStatement): { entity: Entity, relations: InlineRelation[], types: InlineType[] } {
    const astNamespace = removeUndefined({schema: e.schema?.value, catalog: e.catalog?.value, database: e.database?.value})
    const entityNamespace = {...namespace, ...astNamespace}
    const validAttrs = (e.attrs || []).filter(a => !a.path.some(p => p === undefined)) // `path` can be `[undefined]` on invalid input :/
    const attrs = validAttrs.map(a => buildAttribute(namespace, statement, a, {...entityNamespace, entity: e.name.value}))
    const flatAttrs = flattenAttributes(validAttrs).filter(a => !a.path.some(p => p === undefined)) // nested attributes can have `path` be `[undefined]` on invalid input :/
    const pkAttrs = flatAttrs.filter(a => a.primaryKey)
    const indexes: Index[] = buildIndexes(flatAttrs.map(a => ({path: a.path.map(p => p.value), index: a.index ? a.index.name?.value || '' : undefined}))).map(i => removeUndefined({name: i.value, attrs: i.attrs}))
    const uniques: Index[] = buildIndexes(flatAttrs.map(a => ({path: a.path.map(p => p.value), index: a.unique ? a.unique.name?.value || '' : undefined}))).map(i => removeUndefined({name: i.value, attrs: i.attrs, unique: true}))
    const checks: Check[] = buildIndexes(flatAttrs.map(a => ({path: a.path.map(p => p.value), index: a.check ? a.check.definition?.value || '' : undefined}))).map(i => removeUndefined({predicate: i.value || '', attrs: i.attrs}))
    return {
        entity: removeEmpty({
            ...entityNamespace,
            name: e.name.value,
            kind: e.view || e.properties?.find(p => p.key.value === 'view') ? 'view' as const : undefined,
            def: e.properties?.flatMap(p => p.key.value === 'view' && p.value && !Array.isArray(p.value) && p.value.token === 'Identifier' ? [p.value.value.replaceAll(/\\n/g, '\n')] : [])[0],
            attrs: attrs.map(a => a.attribute),
            pk: pkAttrs.length > 0 ? removeUndefined({
                name: pkAttrs.map(a => a.primaryKey?.name?.value).find(isNotUndefined),
                attrs: pkAttrs.map(a => a.path.map(p => p.value)),
            }) : undefined,
            indexes: uniques.concat(indexes),
            checks: checks,
            doc: e.doc?.value,
            stats: undefined,
            extra: buildExtra({line: e.name.position.start.line, statement, alias: e.alias?.value, comment: e.comment?.value}, e, ['view'])
        }),
        relations: attrs.flatMap(a => a.relations),
        types: attrs.flatMap(a => a.types),
    }
}

type InlineRelation = {namespace: Namespace, statement: number, entity: EntityRef, attrs: AttributePath[], ref: AttributeRelationAst}
type InlineType = {type: Type, position: TokenPosition}

function buildAttribute(namespace: Namespace, statement: number, a: AttributeAstNested, entity: EntityRef): { attribute: Attribute, relations: InlineRelation[], types: InlineType[] } {
    const {entity: _, ...entityNamespace} = entity
    const typeExt = a.enumValues && a.enumValues.length <= 2 && a.enumValues.every(v => v.token === 'Integer') ? '(' + a.enumValues.map(stringifyAttrValue).join(',') + ')' : ''
    const enumType: InlineType[] = a.type && a.enumValues && !typeExt ? [{
        type: {...entityNamespace, name: a.type.value, values: a.enumValues.map(stringifyAttrValue), extra: {line: a.enumValues[0].position.start.line, statement, inline: true}},
        position: mergePositions(a.enumValues)
    }] : []
    const relation: InlineRelation[] = a.relation ? [{namespace, statement, entity, attrs: [a.path.map(p => p.value)], ref: a.relation}] : []
    const validAttrs = (a.attrs || []).filter(aa => !aa.path.some(p => p === undefined)) // `path` can be `[undefined]` on invalid input :/
    const nested = validAttrs.map(aa => buildAttribute(namespace, statement, aa, entity))
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
            extra: buildExtra({comment: a.comment?.value}, a, [])
        }),
        relations: relation.concat(nested.flatMap(n => n.relations)),
        types: enumType.concat(nested.flatMap(n => n.types)),
    }
}

function buildAttributeType(a: AttributeAstNested, ext: string): AttributeType {
    return a.type ? a.type.value + ext : legacyColumnTypeUnknown
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

function flattenAttributes(attributes: AttributeAstNested[]): AttributeAstNested[] {
    return attributes.flatMap(a => {
        const {attrs, ...values} = a
        return [values].concat(flattenAttributes(attrs || []))
    })
}

function buildIndexes(indexes: {path: AttributePath, index: string | undefined}[]): {value: string | undefined, attrs: AttributePath[]}[] {
    const indexesByName: Record<string, {path: AttributePath, name: string}[]> = groupBy(indexes.map(i => i.index !== undefined ? {path: i.path, name: i.index} : undefined).filter(isNotUndefined), i => i.name)
    const singleIndexes: {value: string | undefined, attrs: AttributePath[]}[] = (indexesByName[''] || []).map(i => ({value: undefined, attrs: [i.path]}))
    const compositeIndexes: {value: string | undefined, attrs: AttributePath[]}[] = Object.entries(indexesByName).filter(([k, _]) => k !== '').map(([value, values]) => ({value, attrs: values.map(v => v.path)}))
    return compositeIndexes.concat(singleIndexes)
}

function buildRelationStatement(entities: Entity[], namespace: Namespace, statement: number, r: RelationStatement): Relation | undefined {
    const entitySrc = buildEntityRef(r.src, namespace)
    return buildRelation(entities, namespace, statement, r.src.entity.position.start.line, r.kind, entitySrc, r.src.attrs.map(buildAttrPath), r.ref, r.polymorphic, r, false)
}

function buildRelationAttribute(entities: Entity[], namespace: Namespace, statement: number, srcEntity: EntityRef, srcAttrs: AttributePath[], r: AttributeRelationAst): Relation | undefined {
    return buildRelation(entities, namespace, statement, r.ref.entity?.position.start.line, r.kind, srcEntity, srcAttrs, r.ref, r.polymorphic, undefined, true)
}

function buildRelation(entities: Entity[], namespace: Namespace, statement: number, line: number, kind: RelationKindAst | undefined, srcEntity: EntityRef, srcAttrs: AttributePath[], ref: AttributeRefCompositeAst, polymorphic: RelationPolymorphicAst | undefined, extra: ExtraAst | undefined, inline: boolean): Relation | undefined {
    if (!ref || !ref.entity.value || !ref.attrs || ref.attrs.some(a => a.value === undefined)) return undefined // `ref` can be undefined or with empty entity or undefined attrs on invalid input :/ TODO: report an error instead of just ignoring?
    const refEntity = buildEntityRef(ref, namespace)
    const refAttrs: AttributePath[] = ref.attrs.length > 0 ? ref.attrs.map(buildAttrPath) : entities.find(e => entityRefSame(entityToRef(e), refEntity))?.pk?.attrs || [['unknown']]
    const natural = ref.attrs.length === 0 ? (srcAttrs.length === 0 ? 'both' : 'ref') : (srcAttrs.length === 0 ? 'src' : undefined)
    return removeUndefined({
        name: undefined,
        kind: kind ? buildRelationKind(kind) : undefined,
        origin: undefined,
        src: srcEntity,
        ref: refEntity,
        attrs: zip(srcAttrs, refAttrs).map(([srcAttr, refAttr]) => ({src: srcAttr, ref: refAttr})),
        polymorphic: polymorphic ? {attribute: buildAttrPath(polymorphic.attr), value: buildAttrValue(polymorphic.value)} : undefined,
        doc: extra?.doc?.value,
        extra: buildExtra({line, statement, inline: inline ? true : undefined, natural, comment: extra?.comment?.value}, extra || {}, []),
    })
}

function buildRelationKind(k: RelationKindAst): RelationKind | undefined {
    switch (k) {
        case '1-1': return 'one-to-one'
        case '1-n': return 'one-to-many'
        case 'n-1': return undefined // 'many-to-one' is default choice
        case 'n-n': return 'many-to-many'
    }
}

function buildEntityRef(e: EntityRefAst, namespace: Namespace): EntityRef {
    if (e.database || e.catalog || e.schema) {
        return removeUndefined({database: e.database?.value, catalog: e.catalog?.value, schema: e.schema?.value, entity: e.entity.value})
    } else {
        return removeUndefined({...namespace, entity: e.entity.value})
    }
}

function buildAttrPath(a: AttributePathAst): AttributePath {
    return [a.value].concat(a.path?.map(p => p.value) || [])
}

function buildType(namespace: Namespace, statement: number, t: TypeStatement): Type {
    const astNamespace = removeUndefined({schema: t.schema?.value, catalog: t.catalog?.value, database: t.database?.value})
    const typeNamespace = {...namespace, ...astNamespace}
    const content = t.content ? buildTypeContent(namespace, statement, t.content, {...typeNamespace, entity: t.name.value}) : {}
    return removeUndefined({...typeNamespace, name: t.name.value, ...content, doc: t.doc?.value, extra: buildExtra({line: t.name.position.start.line, statement, comment: t.comment?.value}, t, [])})
}

function buildTypeContent(namespace: Namespace, statement: number, t: TypeContentAst, entity: EntityRef): {alias?: string, values?: string[], attrs?: Attribute[], definition?: string} {
    if (t.kind === 'alias') return {alias: t.name.value}
    if (t.kind === 'enum') return {values: t.values.map(stringifyAttrValue)}
    if (t.kind === 'struct') return {attrs: t.attrs.map(a => buildAttribute(namespace, statement, a, entity).attribute)}
    if (t.kind === 'custom') return {definition: t.definition.value}
    return isNever(t)
}

function buildExtra(extra: Extra, v: {properties?: PropertiesAst}, ignore: string[]): Extra {
    const properties = v?.properties
        ?.filter(p => !ignore.includes(p.key.value))
        ?.reduce((acc, prop) => ({...acc, [prop.key.value]: prop.value ? buildPropValue(prop.value) : true}), {} as Record<string, PropertyValue | undefined>) || {}
    return {...properties, ...removeEmpty(extra)}
}

function buildPropValue(v: PropertyValueAst): PropertyValue {
    if (Array.isArray(v)) return v.map(buildPropValue) as PropertyValueBasic[] // ignore nested arrays
    if (v.token === 'Null') return null
    if (v.token === 'Decimal') return v.value
    if (v.token === 'Integer') return v.value
    if (v.token === 'Boolean') return v.value
    if (v.token === 'Expression') return '`' + v.value + '`'
    if (v.token === 'Identifier') return v.value
    return isNever(v)
}
