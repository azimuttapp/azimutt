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
    entityRefSame,
    entityToId,
    entityToRef,
    Extra,
    Index,
    mergePositions,
    Namespace,
    ParserError,
    ParserResult,
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
    isTokenInfo,
    NamespaceStatement,
    PropertiesAst,
    PropertyValueAst,
    RelationKindAst,
    RelationPolymorphicAst,
    RelationStatement,
    TypeContentAst,
    TypeStatement
} from "./ast";
import {parseAmlAst} from "./parser";
import {duplicated} from "./errors";

// TODO: check predicate in parenthesis? (`  age int check(age > 0)=user_age_chk`)
// TODO: check predicate in backticks? (`  age int check`age > 0`=user_age_chk`)
// TODO: several checks on a single column & check on several columns
// TODO: add index order in AML
// TODO: add view definition in AML

export function parseAml(content: string, opts: { strict?: boolean, context?: Database } = {}): ParserResult<Database> {
    const start = Date.now()
    return parseAmlAst(content.trimEnd() + '\n', opts).flatMap(ast => {
        const parsed = Date.now()
        const astErrors: ParserError[] = []
        mapEntriesDeep(ast, (path, value) => {
            if (isTokenInfo(value) && value.issues) {
                value.issues.forEach(i => astErrors.push({...i, offset: value.offset, position: value.position}))
            }
            return value
        })
        const {db, errors: dbErrors} = buildDatabase(ast, start, parsed)
        return new ParserResult(db, astErrors.concat(dbErrors).sort((a, b) => a.offset.start - b.offset.start))
    })
}

export function generateAml(database: Database, legacy: boolean = false): string {
    return genDatabase(database, legacy)
}

// private functions 👇️ (some may be exported for tests)

const defaultType = 'unknown'

function buildDatabase(ast: AmlAst, start: number, parsed: number): {db: Database, errors: ParserError[]} {
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

function genDatabase(database: Database, legacy: boolean): string {
    const [entityRels, aloneRels] = partition(database.relations || [], r => {
        const statement = r.extra?.statement
        return statement ? !!database.entities?.find(e => e.extra?.statement === statement) : false
    })
    const [entityTypes, aloneTypes] = partition(database.types || [], t => {
        const statement = t.extra?.statement
        return statement ? !!database.entities?.find(e => e.extra?.statement === statement) : false
    })
    const entities = (database.entities || []).map((e, i) => {
        const statement = e.extra?.statement
        const rels = statement ? entityRels.filter(r => r.extra?.statement === statement) : []
        const types = statement ? entityTypes : []
        return {index: e.extra?.line || i, kind: 'entity', aml: genEntity(e, rels, types, legacy)}
    })
    const entityCount = entities.length
    const relations = aloneRels.map((r, i) => {
        return {index: r.extra?.line || entityCount + i, kind: 'relation', aml: genRelation(r, legacy)}
    })
    const relationsCount = relations.length
    const types = aloneTypes.map((t, i) => {
        return {index: t.extra?.line || entityCount + relationsCount + i, kind: 'type', aml: genType(t, legacy)}
    })
    const typesCount = types.length
    const comments = database.extra && 'comments' in database.extra && Array.isArray(database.extra.comments) ? database.extra.comments.map((c, i) => {
        return {index: c.line || entityCount + relationsCount + typesCount + i, kind: 'comment', aml: genComment(c.comment).trim() + '\n'}
    }) : []
    const statements = entities.concat(relations, types, comments).sort((a, b) => a.index - b.index)
    return statements.map((statement, i) => {
        if (i === 0) return statement.aml
        const prev = statements[i - 1]
        const newLine = statement.kind === 'entity' || statement.kind !== prev.kind ? '\n' : ''
        return newLine + statement.aml
    }).join('') || ''
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
            extra: buildExtraWithProperties({line: e.name.position.start.line, statement, alias: e.alias?.value, comment: e.comment?.value}, e)
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

function genNamespace(n: Namespace): string {
    const database = n.database ? genIdentifier(n.database) + '.' : ''
    const catalog = n.catalog ? genIdentifier(n.catalog) + '.' : ''
    const schema = n.schema ? genIdentifier(n.schema) + '.' : ''
    return database + catalog + schema
}

export function genEntity(e: Entity, relations: Relation[], types: Type[], legacy: boolean): string {
    const namespace = genNamespace(e)
    const view = e.kind === 'view' ? '*' : ''
    const alias = e.extra?.alias ? ' as ' + genIdentifier(e.extra.alias) : ''
    const entity = `${namespace}${genIdentifier(e.name)}${view}${alias}${genPropertiesExtra(e, ['line', 'statement', 'alias', 'comment'])}${genDoc(e.doc)}${genCommentExtra(e)}\n`
    return entity + (e.attrs ? e.attrs.map(a => genAttribute(a, e, relations.filter(r => r.attrs[0].src[0] === a.name), types, legacy)).join('') : '')
}

function buildIndexes(indexes: {path: AttributePath, index: string | undefined}[]): {value: string | undefined, attrs: AttributePath[]}[] {
    const indexesByName: Record<string, {path: AttributePath, name: string}[]> = groupBy(indexes.map(i => i.index !== undefined ? {path: i.path, name: i.index} : undefined).filter(isNotUndefined), i => i.name)
    const singleIndexes: {value: string | undefined, attrs: AttributePath[]}[] = (indexesByName[''] || []).map(i => ({value: undefined, attrs: [i.path]}))
    const compositeIndexes: {value: string | undefined, attrs: AttributePath[]}[] = Object.entries(indexesByName).filter(([k, _]) => k !== '').map(([value, values]) => ({value, attrs: values.map(v => v.path)}))
    return compositeIndexes.concat(singleIndexes)
}

type InlineRelation = {namespace: Namespace, statement: number, entity: EntityRef, attrs: AttributePath[], ref: AttributeRelationAst}
type InlineType = {type: Type, position: TokenPosition}

function buildAttribute(namespace: Namespace, statement: number, a: AttributeAstNested, entity: EntityRef): { attribute: Attribute, relations: InlineRelation[], types: InlineType[] } {
    const {entity: _, ...entityNamespace} = entity
    const typeExt = a.enumValues && a.enumValues.length <= 2 && a.enumValues.every(v => v.token === 'Integer') ? '(' + a.enumValues.map(stringifyAttrValue).join(',') + ')' : ''
    const enumType: InlineType[] = a.type && a.enumValues && !typeExt ? [{
        type: {...entityNamespace, name: a.type.value, values: a.enumValues.map(stringifyAttrValue), extra: {line: a.enumValues[0].position.start.line, statement}},
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
            extra: buildExtraWithProperties({comment: a.comment?.value}, a)
        }),
        relations: relation.concat(nested.flatMap(n => n.relations)),
        types: enumType.concat(nested.flatMap(n => n.types)),
    }
}

function genAttribute(a: Attribute, e: Entity, relations: Relation[], types: Type[], legacy: boolean, parents: AttributePath = []): string {
    const path = [...parents, a.name]
    const indent = '  '.repeat(path.length)
    const attrRelations = relations.filter(r => attributePathSame(path, r.attrs[0].src))
    const nested = a.attrs?.map(aa => genAttribute(aa, e, relations, types, legacy, path)).join('') || ''
    return indent + genAttributeInner(a, e, attrRelations, types, path, indent, legacy) + '\n' + nested
}

function genAttributeInner(a: Attribute, e: Entity, relations: Relation[], types: Type[], path: AttributePath, indent: string, legacy: boolean): string {
    const pk = e.pk && e.pk.attrs.some(attr => attributePathSame(attr, path)) ? ` pk${e.pk.name ? `=${genIdentifier(e.pk.name)}` : ''}` : ''
    const indexes = (e.indexes || [])
        .map((idx, i) => ({...idx, name: idx.name || (idx.attrs.length > 1 ? `${e.name}_idx_${i + 1}` : undefined)}))
        .filter(i => i.attrs.some(attr => attributePathSame(attr, path)))
        .map(i => ` ${i.unique ? 'unique' : 'index'}${i.name ? `=${genIdentifier(i.name)}` : ''}`)
        .join('')
    const checks = (e.checks || []).filter(i => i.attrs.some(attr => attributePathSame(attr, path))).map(i => ` check${i.predicate ? `=\`${i.predicate}\`` : ''}`).join('')
    const rel = relations.map(r => ' ' + genRelationTarget(r, false, legacy)).join('')
    return `${genIdentifier(a.name)}${genAttributeType(a, types)}${a.null ? ' nullable' : ''}${pk}${indexes}${checks}${rel}${genPropertiesExtra(a, ['comment'])}${genDoc(a.doc, indent)}${genCommentExtra(a)}`
}

function buildAttributeType(a: AttributeAstNested, ext: string): AttributeType {
    return a.type ? a.type.value + ext : defaultType
}

function genAttributeType(a: Attribute, types: Type[]): string {
    // regex from `Identifier` token to know if it should be escaped or not (cf libs/aml/src/parser.ts:7)
    const typeName = a.type && a.type !== defaultType ? ' ' + genIdentifier(a.type) : ''
    const enumType = types.find(t => t.name === a.type && t.values)
    const enumValues = enumType ? '(' + enumType.values?.map(genAttributeValueStr).join(', ') + ')' : ''
    const defaultValue = a.default !== undefined ? `=${genAttributeValue(a.default)}` : ''
    return typeName ? typeName + enumValues + defaultValue : ''
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
        extra: buildExtraWithProperties({line, statement, inline: inline ? true : undefined, natural, comment: extra?.comment?.value}, extra || {}),
    })
}

function genRelation(r: Relation, legacy: boolean): string {
    const srcNatural: boolean = !r.extra?.inline && (r.extra?.natural === 'src' || r.extra?.natural === 'both')
    return `${legacy ? 'fk' : 'rel'} ${genAttributeRef(r.src, r.attrs.map(a => a.src), srcNatural, legacy)} ${genRelationTarget(r, true, legacy)}${genPropertiesExtra(r, ['line', 'statement', 'inline', 'natural', 'comment'])}${genDoc(r.doc)}${genCommentExtra(r)}\n`
}

function genRelationTarget(r: Relation, standalone: boolean, legacy: boolean): string {
    const poly = r.polymorphic ? `${r.polymorphic.attribute}=${r.polymorphic.value}` : ''
    const [qSrc, qRef] = (r.kind || 'many-to-one').split('-to-')
    const aSecond = qSrc === 'many' ? '>' : '-'
    const aFirst = qRef === 'many' ? '<' : '-'
    const refNatural = r.extra?.natural === 'ref' || r.extra?.natural === 'both'
    return `${legacy && !standalone ? 'fk' : aFirst + poly + aSecond} ${genAttributeRef(r.ref, r.attrs.map(a => a.ref), refNatural, legacy)}`
}

function buildType(namespace: Namespace, statement: number, t: TypeStatement): Type {
    const astNamespace = removeUndefined({schema: t.schema?.value, catalog: t.catalog?.value, database: t.database?.value})
    const typeNamespace = {...namespace, ...astNamespace}
    const content = t.content ? buildTypeContent(namespace, statement, t.content, {...typeNamespace, entity: t.name.value}) : {}
    return removeUndefined({...typeNamespace, name: t.name.value, ...content, doc: t.doc?.value, extra: buildExtraWithProperties({line: t.name.position.start.line, statement, comment: t.comment?.value}, t)})
}

function buildTypeContent(namespace: Namespace, statement: number, t: TypeContentAst, entity: EntityRef): {definition?: string, values?: string[], attrs?: Attribute[]} {
    if (t.kind === 'alias') return {definition: t.name.value}
    if (t.kind === 'enum') return {values: t.values.map(stringifyAttrValue)}
    if (t.kind === 'struct') return {attrs: t.attrs.map(a => buildAttribute(namespace, statement, a, entity).attribute)}
    if (t.kind === 'custom') return {definition: t.definition.value}
    return isNever(t)
}

function genType(t: Type, legacy: boolean): string {
    return `type ${genEntityRef({...t, entity: t.name})}${genTypeContent(t, legacy)}${genPropertiesExtra(t, ['line', 'statement', 'comment'])}${genDoc(t.doc)}${genCommentExtra(t)}\n`
}

function genTypeContent(t: Type, legacy: boolean): string {
    if (t.definition && t.definition.match(/[ (]/)) return ' `' + t.definition + '`'
    if (t.definition) return ' ' + t.definition
    if (t.values) return ' (' + t.values.map(genIdentifier).join(', ') + ')'
    if (t.attrs) return ' {' + t.attrs.map(a => genAttributeInner(a, {name: t.name}, [], [], [a.name], '', legacy)).join(', ') + '}'
    return ''
}

export function genAttributeRef(e: EntityRef, attrs: AttributePath[], natural: boolean, legacy: boolean): string {
    if (legacy) return `${genEntityRef(e)}.${attrs.map(a => genAttributePath(a, legacy)).join(':')}`
    return `${genEntityRef(e)}${natural || attrs.length === 0 ? '' : `(${attrs.map(a => genAttributePath(a, legacy)).join(', ')})`}`
}

function genEntityRef(e: EntityRef): string {
    if (e.database) return [e.database, e.catalog, e.schema, e.entity].join('.')
    if (e.catalog) return [e.catalog, e.schema, e.entity].join('.')
    if (e.schema) return [e.schema, e.entity].join('.')
    return e.entity
}

function genAttributePath(p: AttributePath, legacy: boolean): string {
    return p.map(genIdentifier).join(legacy ? ':' : '.')
}

export const keywords = ['namespace', 'as', 'nullable', 'pk', 'fk', 'index', 'unique', 'check', 'rel', 'type']

function genIdentifier(identifier: string): string {
    if (keywords.includes(identifier.trim().toLowerCase())) return '"' + identifier + '"'
    if (identifier.match(/^[a-zA-Z_][a-zA-Z0-9_#(),]*$/)) return identifier
    return '"' + identifier + '"'
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

function genAttributeValue(v: AttributeValue): string {
    if (v === undefined) return ''
    if (v === null) return 'null'
    if (typeof v === 'string') return v.startsWith('`') ? v : genIdentifier(v)
    if (typeof v === 'number') return v.toString()
    if (typeof v === 'boolean') return v.toString()
    return `${v}`
}

function genAttributeValueStr(value: string): string {
    if (value.match(/^\d+(\.\d+)?$/)) return value
    if (value.match(/^true|false$/i)) return value
    return genIdentifier(value)
}

type PropertyValueBasic = null | number | boolean | string
type PropertyValue = PropertyValueBasic | PropertyValueBasic[]

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

function genPropertyValue(v: PropertyValue): string {
    if (Array.isArray(v)) return '[' + v.map(genPropertyValue).join(', ') + ']'
    if (v === null) return 'null'
    if (typeof v === 'string') return genIdentifier(v)
    if (typeof v === 'number') return v.toString()
    if (typeof v === 'boolean') return v.toString()
    return isNever(v)
}

function buildExtraWithProperties(extra: Extra, v: {properties?: PropertiesAst}): Extra {
    const properties = v?.properties?.reduce((acc, prop) => ({...acc, [prop.key.value]: prop.value ? buildPropValue(prop.value) : true}), {} as Record<string, PropertyValue | undefined>) || {}
    return {...properties, ...removeEmpty(extra)}
}

function genPropertiesExtra(v: {extra?: Extra | undefined}, ignore: string[] = []): string {
    return v.extra ? genProperties(Object.fromEntries(Object.entries(v.extra).filter(([k, ]) => !ignore.includes(k)))) : ''
}

function genProperties(properties: Record<string, PropertyValue>): string {
    return Object.keys(properties).length > 0 ? ' {' + Object.entries(properties).map(([key, value]) => value !== undefined && value !== true ? `${key}: ${genPropertyValue(value)}` : key).join(', ') + '}' : ''
}

function genDoc(doc: string | undefined, indent: string = ''): string {
    if (!doc) return ''
    if (doc.indexOf('\n') === -1) return ' | ' + doc.replaceAll(/#/g, '\\#')
    return ' |||\n' + doc.split('\n').map(l => indent + '  ' + l + '\n').join('') + indent + '|||'
}

function genCommentExtra(v: {extra?: Extra | undefined}): string {
    return v.extra && 'comment' in v.extra ? genComment(v.extra.comment) : ''
}

function genComment(comment: string | undefined): string {
    return comment !== undefined ? ' # ' + comment : ''
}
