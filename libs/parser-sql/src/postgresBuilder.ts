import {distinctBy, isNever, removeEmpty, removeUndefined} from "@azimutt/utils";
import {
    AttributeName,
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
    FunctionAst,
    Operator,
    OperatorLeft,
    OperatorRight,
    PostgresAst,
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
        })) || selectAttrs(stmt.query, entities).map(name => ({name, type: 'unknown'})),
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

function selectAttrs(s: SelectStatementInnerAst, entities: Entity[]): AttributeName[] {
    return s.columns.map((c, i) => {
        if (c.alias) return c.alias.name.value
        if (c.kind === 'Column') return c.column.value
        if (c.kind === 'Function') return c.function.value
        return `col_${i + 1}` // TODO: improve
    })
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
