import {distinctBy, isNever, removeEmpty, removeUndefined} from "@azimutt/utils";
import {
    AttributePath,
    attributePathSame,
    Check,
    Database,
    Entity,
    entityRefSame,
    entityToId,
    entityToRef,
    Index,
    mergeEntity,
    mergePositions,
    ParserError,
    PrimaryKey,
    Relation,
    TokenPosition
} from "@azimutt/models";
import packageJson from "../package.json";
import {
    AliasAst,
    ColumnAst,
    CreateTableStatementAst,
    CreateViewStatementAst,
    ExpressionAst,
    FromClauseAst,
    FromItemAst,
    FunctionAst,
    Operator,
    OperatorLeft,
    OperatorRight,
    PostgresAst,
    SelectClauseColumnAst,
    SelectStatementInnerAst
} from "./postgresAst";
import {duplicated} from "./errors";

export function buildPostgresDatabase(ast: PostgresAst, start: number, parsed: number): {db: Database, errors: ParserError[]} {
    const db: Database = {entities: [], relations: [], types: []}
    const errors: ParserError[] = []
    ast.statements.forEach((stmt, i) => {
        const index = i + 1
        if (stmt.kind === 'AlterTable') {
            // TODO
        } else if (stmt.kind === 'CommentOn') {
            // TODO
        } else if (stmt.kind === 'CreateIndex') {
            // TODO
        } else if (stmt.kind === 'CreateMaterializedView') {
            // TODO
        } else if (stmt.kind === 'CreateTable') {
            if (!db.entities) db.entities = []
            const res = buildCreateTable(index, stmt)
            addEntity(db.entities, errors, res.entity, mergePositions([stmt.schema, stmt.name].map(v => v?.token)))
            res.relations.forEach(r => db.relations?.push(r))
        } else if (stmt.kind === 'CreateType') {
            // TODO
        } else if (stmt.kind === 'CreateView') {
            if (!db.entities) db.entities = []
            const entity = buildCreateView(index, stmt, db.entities)
            addEntity(db.entities, errors, entity, mergePositions([stmt.schema, stmt.name].map(v => v?.token)))
        }
    })
    const done = Date.now()
    const extra = removeEmpty({
        source: `PostgreSQL parser <${packageJson.version}>`,
        createdAt: new Date().toISOString(),
        creationTimeMs: done - start,
        parsingTimeMs: parsed - start,
        formattingTimeMs: done - parsed,
        comments: ast.comments?.map(c => ({line: c.token.position.start.line, comment: c.value})) || [],
    })
    return {db: removeEmpty({...db, extra}), errors}
}

function addEntity(entities: Entity[], errors: ParserError[], entity: Entity, pos: TokenPosition): void {
    const ref = entityToRef(entity)
    const prevIndex = entities.findIndex(e => entityRefSame(entityToRef(e), ref))
    if (prevIndex !== -1) {
        const prev = entities[prevIndex]
        errors.push(duplicated(`Entity ${entityToId(entity)}`, prev.extra?.line ? prev.extra.line : undefined, pos))
        entities[prevIndex] = mergeEntity(prev, entity)
    } else {
        entities.push(entity)
    }
}

function buildCreateTable(index: number, stmt: CreateTableStatementAst): { entity: Entity, relations: Relation[] } {
    const colPk: PrimaryKey[] = stmt.columns?.flatMap(col => col.constraints?.flatMap(c => c.kind === 'PrimaryKey' ? [removeUndefined({attrs: [[col.name.value]], name: c.constraint?.name.value})] : []) || []) || []
    const tablePk: PrimaryKey[] = stmt.constraints?.flatMap(c => c.kind === 'PrimaryKey' ? [removeUndefined({attrs: c.columns.map(col => [col.value]), name: c.constraint?.name.value})] : []) || []
    const pk: PrimaryKey[] = colPk.concat(tablePk)
    const colIndexes: Index[] = stmt.columns?.flatMap(col => col.constraints?.flatMap(c => c.kind === 'Unique' ? [removeUndefined({attrs: [[col.name.value]], unique: true, name: c.constraint?.name.value})] : []) || []) || []
    const tableIndexes: Index[] = stmt.constraints?.flatMap(c => c.kind === 'Unique' ? [removeUndefined({attrs: c.columns.map(col => [col.value]), unique: true, name: c.constraint?.name.value})] : []) || []
    const indexes: Index[] = colIndexes.concat(tableIndexes)
    const colChecks: Check[] = stmt.columns?.flatMap(col => col.constraints?.flatMap(c => c.kind === 'Check' ? [removeUndefined({attrs: [[col.name.value]], predicate: expressionToString(c.predicate), name: c.constraint?.name.value})] : []) || []) || []
    const tableChecks: Check[] = stmt.constraints?.flatMap(c => c.kind === 'Check' ? [removeUndefined({attrs: expressionAttrs(c.predicate), predicate: expressionToString(c.predicate), name: c.constraint?.name.value})] : []) || []
    const checks: Check[] = colChecks.concat(tableChecks)
    const colRels: Relation[] = stmt.columns?.flatMap(col => col.constraints?.flatMap(c => c.kind === 'ForeignKey' ? [removeUndefined({
        name: c.constraint?.name.value,
        src: removeUndefined({schema: stmt.schema?.value, entity: stmt.name.value, attrs: [[col.name.value]]}),
        ref: removeUndefined({schema: c.schema?.value, entity: c.table.value, attrs: [c.column ? [c.column.value] : []]}),
    })] : []) || []) || []
    const tableRels: Relation[] = stmt.constraints?.flatMap(c => c.kind === 'ForeignKey' ? [removeUndefined({
        name: c.constraint?.name.value,
        src: removeUndefined({schema: stmt.schema?.value, entity: stmt.name.value, attrs: c.columns.map(col => [col.value])}),
        ref: removeUndefined({schema: c.ref.schema?.value, entity: c.ref.table.value, attrs: c.ref.columns?.map(col => [col.value]) || []}),
    })] : []) || []
    const relations: Relation[] = colRels.concat(tableRels)
    return {entity: removeEmpty({
        schema: stmt.schema?.value,
        name: stmt.name.value,
        kind: undefined,
        def: undefined,
        attrs: (stmt.columns || []).map(c => removeUndefined({
            name: c.name.value,
            type: c.type.name.value,
            null: c.constraints?.find(c => c.kind === 'Nullable' ? !c.value : false) || pk.find(pk => pk.attrs.some(a => attributePathSame(a, [c.name.value]))) ? undefined : true,
            // gen: z.boolean().optional(), // not handled for now
            default: (c.constraints || []).flatMap(c => c.kind === 'Default' ? [expressionToString(c.expression)] : [])[0],
            // attrs: z.lazy(() => Attribute.array().optional()), // no nested attrs from SQL
            // doc: z.string().optional(), // not defined in CREATE TABLE
            // stats: AttributeStats.optional(), // no stats in SQL
            // extra: AttributeExtra.optional(), // TODO
        })),
        pk: pk.length > 0 ? pk[0] : undefined,
        indexes,
        checks,
        // doc: z.string().optional(), // not defined in CREATE TABLE
        // stats: EntityStats.optional(), // no stats in SQL
        // extra: EntityExtra.optional(), // TODO
    }), relations}
}

function buildCreateView(index: number, stmt: CreateViewStatementAst, entities: Entity[]): Entity {
    return removeEmpty({
        schema: stmt.schema?.value,
        name: stmt.name.value,
        kind: 'view' as const,
        def: selectInnerToString(stmt.query),
        attrs: stmt.columns?.map(c => removeUndefined({
            name: c.value,
            type: 'unknown',
            // null: z.boolean().optional(), // not in VIEW
            // gen: z.boolean().optional(), // not handled for now
            // default: AttributeValue.optional(), // now in VIEW
            // attrs: z.lazy(() => Attribute.array().optional()), // no nested attrs from SQL
            // doc: z.string().optional(), // not defined in CREATE TABLE
            // stats: AttributeStats.optional(), // no stats in SQL
            // extra: AttributeExtra.optional(), // TODO
        })) || selectEntities(stmt.query, entities).columns.map(c => ({name: c.name, type: c.type || 'unknown'})),
        // pk: PrimaryKey.optional(), // not in VIEW
        // indexes: Index.array().optional(), // not in VIEW
        // checks: Check.array().optional(), // not in VIEW
        // doc: z.string().optional(), // not in VIEW
        // stats: EntityStats.optional(), // no stats in SQL
        // extra: EntityExtra.optional(), // TODO
    })
}

function selectInnerToString(s: SelectStatementInnerAst): string {
    const select = 'SELECT ' + s.columns.map(c => expressionToString(c) + (c.alias ? ' ' + aliasToString(c.alias) : '')).join(', ')
    const from = s.from ? fromToString(s.from) : ''
    const where = s.where ? ' WHERE ' + expressionToString(s.where.predicate) : ''
    return select + from + where
}

function fromToString(f: FromClauseAst): string {
    if (f.kind === 'Table') return ' FROM ' + (f.schema ? f.schema.value + '.' : '') + f.table.value + (f.alias ? ' ' + aliasToString(f.alias) : '')
    if (f.kind === 'Select') return ' FROM (' + selectInnerToString(f.select) + ')' + (f.alias ? ' ' + aliasToString(f.alias) : '')
    return isNever(f)
}

function aliasToString(a: AliasAst): string {
    return (a.token ? 'AS ' : '') + a.name.value
}

function expressionToString(e: ExpressionAst): string {
    if (e.kind === 'String') return "'" + e.value + "'"
    if (e.kind === 'Integer') return e.value.toString()
    if (e.kind === 'Decimal') return e.value.toString()
    if (e.kind === 'Boolean') return e.value.toString()
    if (e.kind === 'Null') return 'null'
    if (e.kind === 'Parameter') return e.value
    if (e.kind === 'Column') return columnToString(e)
    if (e.kind === 'Wildcard') return (e.schema ? e.schema.value + '.' : '') + (e.table ? e.table.value + '.' : '') + '*'
    if (e.kind === 'Function') return functionToString(e)
    if (e.kind === 'Group') return '(' + expressionToString(e.expression) + ')'
    if (e.kind === 'Operation') return expressionToString(e.left) + ' ' + operatorToString(e.op.kind) + ' ' + expressionToString(e.right)
    if (e.kind === 'OperationLeft') return operatorLeftToString(e.op.kind) + ' ' + expressionToString(e.right)
    if (e.kind === 'OperationRight') return expressionToString(e.left) + ' ' + operatorRightToString(e.op.kind)
    if (e.kind === 'List') return '(' + e.items.map(expressionToString).join(', ') + ')'
    return isNever(e)
}

function columnToString(c: ColumnAst): string {
    const schema = c.schema ? c.schema.value + '.' : ''
    const table = c.table ? c.table.value + '.' : ''
    const json = c.json ? c.json.map(j => j.kind + j.field.value).join('') : ''
    return schema + table + c.column.value + json
}

function functionToString(f: FunctionAst): string {
    const schema = f.schema ? f.schema.value + '.' : ''
    const distinct = f.distinct ? 'distinct ' : ''
    const params = f.parameters.map(expressionToString).join(', ')
    return schema + f.function.value + '(' + distinct + params + ')'
}

function operatorToString(o: Operator): string {
    if (o === 'Or') return 'OR'
    if (o === 'And') return 'AND'
    if (o === 'Is') return 'IS'
    if (o === 'In') return 'IN'
    if (o === 'NotIn') return 'NOT IN'
    if (o === 'Like') return 'LIKE'
    if (o === 'NotLike') return 'NOT LIKE'
    return o
}

function operatorLeftToString(o: OperatorLeft): string {
    if (o === 'Not') return 'NOT'
    if (o === 'Interval') return 'INTERVAL'
    return o
}

function operatorRightToString(o: OperatorRight): string {
    if (o === 'IsNull') return 'IS NULL'
    if (o === 'NotNull') return 'IS NOT NULL'
    return o
}

function expressionAttrs(e: ExpressionAst): AttributePath[] {
    if (e.kind === 'String') return []
    if (e.kind === 'Integer') return []
    if (e.kind === 'Decimal') return []
    if (e.kind === 'Boolean') return []
    if (e.kind === 'Null') return []
    if (e.kind === 'Parameter') return []
    if (e.kind === 'Column') return [[e.column.value]]
    if (e.kind === 'Wildcard') return []
    if (e.kind === 'Function') return distinctBy(e.parameters.flatMap(expressionAttrs), p => p.join('.'))
    if (e.kind === 'Group') return expressionAttrs(e.expression)
    if (e.kind === 'Operation') return distinctBy(expressionAttrs(e.left).concat(expressionAttrs(e.right)), p => p.join('.'))
    if (e.kind === 'OperationLeft') return expressionAttrs(e.right)
    if (e.kind === 'OperationRight') return expressionAttrs(e.left)
    if (e.kind === 'List') return []
    return isNever(e)
}

export type SelectEntities = { columns: SelectColumn[], sources: SelectSource[] }
export type SelectColumn = { schema?: string, table?: string, name: string, type?: string, sources: SelectColumnSource[] }
export type SelectColumnSource = { schema?: string, table: string, column: string, type?: string }
export type SelectSource = { name: string, from: SelectSourceFrom }
export type SelectSourceFrom = SelectSourceTable | SelectSourceSelect
export type SelectSourceTable = { kind: 'Table', schema?: string, table: string, columns?: { name: string, type: string }[] }
export type SelectSourceSelect = { kind: 'Select' } & SelectEntities

export function selectEntities(s: SelectStatementInnerAst, entities: Entity[]): SelectEntities {
    const sources = s.from ? selectTables(s.from, entities) : []
    const columns: SelectColumn[] = s.columns.flatMap((c, i) => selectColumn(c, i, sources))
    return {columns, sources}
}
function selectTables(f: FromClauseAst, entities: Entity[]): SelectSource[] {
    const joins = f.joins?.map(j => fromTables(j.from, entities)) || []
    return [fromTables(f, entities), ...joins]
}
function fromTables(i: FromItemAst, entities: Entity[]): SelectSource {
    if (i.kind === 'Table') {
        const entity = findEntity(entities, i.table.value, i.schema?.value)
        if (entity) {
            return {name: i.alias?.name.value || i.table.value, from: removeEmpty({kind: 'Table' as const, schema: entity.schema, table: entity.name, columns: entity.attrs?.map(a => ({name: a.name, type: a.type})) || []})}
        } else {
            return {name: i.alias?.name.value || i.table.value, from: removeUndefined({kind: 'Table' as const, schema: i.schema?.value, table: i.table.value})}
        }
    } else if (i.kind === 'Select') {
        return {name: i.alias?.name.value || '', from: {kind: 'Select', ...selectEntities(i.select, entities)}}
    } else {
        return isNever(i)
    }
}
function selectColumn(c: SelectClauseColumnAst, i: number, sources: SelectSource[]): SelectColumn[] {
    if(c.kind === 'Column') {
        const ref = removeUndefined({schema: c.schema?.value, table: c.table?.value, name: columnName(c, i)})
        const source = findSource(sources, c.schema?.value, c.table?.value, c.column.value)?.from
        if (source?.kind === 'Table') {
            const col = source.columns?.find(col => col.name === c.column.value)
            return [removeUndefined({...ref, type: col?.type, sources: [removeUndefined({schema: source.schema, table: source.table, column: c.column.value, type: col?.type})]})]
        } else if (source?.kind === 'Select') {
            const col = source.columns.find(col => col.name === c.column.value)
            return [col ? col : {...ref, sources: []}] // `col` should always exist in correct queries
        } else {
            return [{...ref, sources: []}] // `source` should always exist in correct queries
        }
    } else if (c.kind === 'Wildcard') {
        const ref = removeUndefined({schema: c.schema?.value, table: c.table?.value, name: columnName(c, i)})
        const source = findSource(sources, c.schema?.value, c.table?.value, undefined)?.from
        if (source?.kind === 'Table') {
            const cols = source.columns || []
            if(cols.length > 0) {
                return cols.map(a => ({...ref, name: a.name, type: a.type, sources: [removeUndefined({schema: source.schema, table: source.table, column: a.name, type: a.type})]}))
            } else {
                return [{...ref, sources: []}] // Wildcard from a table with no columns :/ (happen when missing entities)
            }
        } else if (source?.kind === 'Select') {
            return source.columns.map(col => removeUndefined({...col, schema: c.schema?.value, table: c.table?.value}))
        } else {
            return [{...ref, sources: []}] // `source` should always exist in correct queries
        }
    } else {
        // TODO: handle more kind and remove `columnSources`
        return [{name: columnName(c, i), sources: columnSources(c, sources)}]
    }
}
function findEntity(entities: Entity[], entity: string, schema: string | undefined): Entity | undefined {
    const candidates = entities.filter(e => e.name === entity)
    if (schema !== undefined) return candidates.find(e => e.schema === schema)
    if (candidates.length === 1) return candidates[0]
    return candidates.find(e => e.schema === undefined) || candidates.find(e => e.schema === '')
}
function findSource(sources: SelectSource[], schema: string | undefined, table: string | undefined, column: string | undefined): SelectSource | undefined {
    // not sure what to do with `schema` :/
    if (table) {
        return sources.find(s => s.name === table)
    }
    if (column) {
        const candidates = sources.filter(s => {
            if (s.from.kind === 'Table') {
                return !!s.from.columns?.find(a => a.name === column)
            } else if (s.from.kind === 'Select') {
                return !!s.from.columns.find(c => c.name === column)
            } else {
                return isNever(s.from)
            }
        })
        return candidates.length === 1 ? candidates[0] : sources.length === 1 ? sources[0] : undefined
    }
    return sources.length === 1 ? sources[0] : undefined
}
function columnName(c: SelectClauseColumnAst, i: number): string {
    if (c.alias) return c.alias.name.value
    if (c.kind === 'Column') return c.column.value
    if (c.kind === 'Function') return c.function.value
    if (c.kind === 'Wildcard') return '*'
    return `col_${i + 1}`
}
function columnSources(c: SelectClauseColumnAst, sources: SelectSource[]): SelectColumnSource[] {
    if (c.kind === 'Column') {
        const source = c.table ? sources.find(s => s.name === c.table?.value) : sources.length === 1 ? sources[0] : undefined
        if (source && source.from.kind === 'Table') {
            return [removeUndefined({schema: source.from.schema, table: source.from.table, column: c.column.value})]
        }
    }
    if (c.kind === 'Function') return c.parameters.flatMap(p => columnSources(p, sources))
    if (c.kind === 'Operation') return columnSources(c.left, sources).concat(columnSources(c.right, sources))
    if (c.kind === 'OperationLeft') return columnSources(c.right, sources)
    if (c.kind === 'OperationRight') return columnSources(c.left, sources)
    if (c.kind === 'Group') return columnSources(c.expression, sources)
    return []
}
