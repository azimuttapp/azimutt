import {
    groupBy,
    mapEntriesAsync,
    mapValuesAsync,
    partition,
    removeEmpty,
    removeSurroundingParentheses,
    removeUndefined,
    safeJsonParse
} from "@azimutt/utils";
import {
    Attribute,
    AttributeName,
    AttributePath,
    Check,
    ConnectorSchemaOpts,
    connectorSchemaOptsDefaults,
    Database,
    Entity,
    EntityId,
    EntityRef,
    formatAttributeRef,
    formatEntityRef,
    Index,
    parseEntityRef,
    PrimaryKey,
    Relation,
    schemaToAttributes,
    ValueSchema,
    valuesToSchema
} from "@azimutt/database-model";
import {buildColumnType, buildSqlColumn, buildSqlTable, handleError, scopeFilter} from "./helpers";
import {Conn} from "./connect";

export const getSchema = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<Database> => {
    // access system tables only
    const columns: Record<EntityId, RawColumn[]> = await getColumns(opts)(conn).then(groupByEntity)
    const indexColumns: Record<EntityId, RawIndexColumn[]> = await getIndexColumns(opts)(conn).then(groupByEntity)
    const checks: Record<EntityId, RawCheck[]> = await getChecks(opts)(conn).then(groupByEntity)
    const comments: Record<EntityId, RawComment[]> = await getComments(opts)(conn).then(groupByEntity)
    const foreignKeyColumns: RawForeignKeyColumn[] = await getForeignKeyColumns(opts)(conn)
    // access table data when options are requested
    const jsonColumns: Record<EntityId, Record<AttributeName, ValueSchema>> = opts.inferJsonAttributes ? await getJsonColumns(columns, checks, opts)(conn) : {}
    // build the database
    return removeUndefined({
        entities: Object.entries(columns).map(([id, columns]) => buildEntity(
            columns,
            indexColumns[id] || [],
            checks[id] || [],
            comments[id] || [],
            jsonColumns[id] || {}
        )),
        relations: Object.values(groupBy(foreignKeyColumns, c => c.constraint_name)).map(cols => buildRelation(cols)),
        types: undefined,
        doc: undefined,
        stats: undefined,
        extra: undefined,
    })
}

// 👇️ Private functions, some are exported only for tests
// If you use them, beware of breaking changes!

const toEntityId = <T extends { table_schema: string, table_name: string }>(value: T): EntityId => formatEntityRef({schema: value.table_schema, entity: value.table_name})
const groupByEntity = <T extends { table_schema: string, table_name: string }>(values: T[]): Record<EntityId, T[]> => groupBy(values, toEntityId)

type RawColumn = {
    table_schema: string
    table_name: string
    table_kind: 'BASE TABLE' | 'VIEW'
    column_name: string
    column_type: string
    column_index: number
    column_default: string | null
    column_nullable: 'YES' | 'NO'
}

const getColumns = ({schema, entity, logger, ignoreErrors}: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawColumn[]> => {
    return conn.query<RawColumn>(`
        SELECT c.TABLE_SCHEMA          AS table_schema,
               c.TABLE_NAME            AS table_name,
               t.TABLE_TYPE            AS table_kind,
               c.COLUMN_NAME           AS column_name,
               ${buildColumnType('c')} AS column_type,
               c.ORDINAL_POSITION      AS column_index,
               c.COLUMN_DEFAULT        AS column_default,
               c.IS_NULLABLE           AS column_nullable
        FROM information_schema.COLUMNS c
                 JOIN information_schema.TABLES t ON c.TABLE_SCHEMA = t.TABLE_SCHEMA AND c.TABLE_NAME = t.TABLE_NAME
        WHERE ${scopeFilter('c.TABLE_SCHEMA', schema, 'c.TABLE_NAME', entity)}
        ORDER BY table_schema, table_name, column_index;`, [], 'getColumns'
    ).catch(handleError(`Failed to get columns`, [], {logger, ignoreErrors}))
}

function buildEntity(columns: RawColumn[], indexColumns: RawIndexColumn[], checks: RawCheck[], comments: RawComment[], jsonColumns: Record<AttributeName, ValueSchema>): Entity {
    const indexes = groupBy(indexColumns, c => c.constraint_name)
    const [pk, idxs] = partition(Object.values(indexes), i => i[0].constraint_type === 'PRIMARY KEY')
    return removeEmpty({
        schema: columns[0].table_schema,
        name: columns[0].table_name,
        kind: columns[0].table_kind === 'VIEW' ? 'view' as const : undefined,
        def: undefined,
        attrs: columns.slice(0).sort((a, b) => a.column_index - b.column_index).map(c => buildAttribute(c, comments, jsonColumns[c.column_name])),
        pk: pk.length > 0 ? buildPrimaryKey(pk[0]) : undefined,
        indexes: idxs.map(buildIndex),
        checks: checks.map(buildCheck),
        doc: comments.find(c => c.column_name === null)?.comment,
        stats: undefined,
        extra: undefined
    })
}

function buildAttribute(column: RawColumn, comments: RawComment[], jsonColumn: ValueSchema | undefined): Attribute {
    return removeUndefined({
        name: column.column_name,
        type: column.column_name,
        nullable: column.column_nullable === 'YES' ? true : undefined,
        generated: undefined,
        default: column.column_default ? removeSurroundingParentheses(column.column_default) : undefined,
        values: undefined,
        attrs: jsonColumn ? schemaToAttributes(jsonColumn, 0) : undefined,
        doc: comments.find(c => c.column_name === column.column_name)?.comment,
        stats: undefined,
        extra: undefined
    })
}

type RawIndexColumn = {
    table_schema: string
    table_name: string
    constraint_name: string
    constraint_type: 'PRIMARY KEY' | 'UNIQUE' | 'INDEX'
    column_name: string
    column_index?: number
}

const getIndexColumns = ({schema, entity, logger, ignoreErrors}: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawIndexColumn[]> => {
    return conn.query<RawIndexColumn>(`
        SELECT OBJECT_SCHEMA_NAME(i.object_id)     AS table_schema,
               OBJECT_NAME(i.object_id)            AS table_name,
               i.name                              AS constraint_name,
               CASE
                   WHEN OBJECTPROPERTY(OBJECT_ID(OBJECT_SCHEMA_NAME(i.object_id) + '.' + QUOTENAME(i.name)), 'IsPrimaryKey') = 1
                       THEN 'PRIMARY KEY'
                   WHEN i.is_unique = 1
                       THEN 'UNIQUE'
                   ELSE 'INDEX' END                AS constraint_type,
               COL_NAME(i.object_id, ic.column_id) AS column_name,
               ic.key_ordinal                      as column_index
        FROM sys.indexes i
                 JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
        WHERE ${scopeFilter('OBJECT_SCHEMA_NAME(i.object_id)', schema, 'OBJECT_NAME(i.object_id)', entity)};`, [], 'getIndexColumns'
    ).catch(handleError(`Failed to get index columns (pks, uniques & indexes)`, [], {logger, ignoreErrors}))
}

function buildPrimaryKey(columns: RawIndexColumn[]): PrimaryKey {
    const first = columns[0]
    return {
        name: first.constraint_name,
        attrs: columns.slice(0)
            .sort((a, b) => (a.column_index || 0) - (b.column_index || 0))
            .map(c => [c.column_name]),
        doc: undefined,
        stats: undefined,
        extra: undefined
    }
}

function buildIndex(columns: RawIndexColumn[]): Index {
    const first = columns[0]
    return removeUndefined({
        name: first.constraint_name,
        attrs: columns.slice(0)
            .sort((a, b) => (a.column_index || 0) - (b.column_index || 0))
            .map(c => [c.column_name]),
        unique: first.constraint_type === 'UNIQUE' ? true : undefined,
        partial: undefined,
        definition: undefined,
        doc: undefined,
        stats: undefined,
        extra: undefined
    })
}

type RawCheck = {
    table_schema: string
    table_name: string
    constraint_name: string
    column_name: string
    definition: string
}

const getChecks = ({schema, entity, logger, ignoreErrors}: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawCheck[]> => {
    return conn.query<RawCheck>(`
        SELECT SCHEMA_NAME(t.schema_id) AS table_schema,
               t.name                   AS table_name,
               con.name                 AS constraint_name,
               c.name                   AS column_name,
               con.definition
        FROM sys.check_constraints con
                 LEFT OUTER JOIN sys.objects t ON con.parent_object_id = t.object_id
                 LEFT OUTER JOIN sys.all_columns c ON con.parent_column_id = c.column_id AND con.parent_object_id = c.object_id
        WHERE con.is_disabled = 'false' AND ${scopeFilter('SCHEMA_NAME(t.schema_id)', schema, 't.name', entity)};`, [], 'getChecks'
    ).catch(handleError(`Failed to get checks`, [], {logger, ignoreErrors}))
}

function buildCheck(check: RawCheck): Check {
    return removeUndefined({
        name: check.constraint_name,
        attrs: [[check.column_name]],
        predicate: check.definition,
        doc: undefined,
        stats: undefined,
        extra: undefined
    })
}

type RawComment = {
    table_schema: string
    table_name: string
    column_name?: string
    comment: string
}

const getComments = ({schema, entity, logger, ignoreErrors}: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawComment[]> => {
    // https://learn.microsoft.com/sql/relational-databases/system-catalog-views/extended-properties-catalog-views-sys-extended-properties
    // https://learn.microsoft.com/sql/relational-databases/system-catalog-views/sys-objects-transact-sql
    // https://learn.microsoft.com/sql/relational-databases/system-compatibility-views/sys-sysusers-transact-sql
    // https://learn.microsoft.com/sql/relational-databases/system-catalog-views/sys-columns-transact-sql
    return conn.query<RawComment>(`
        SELECT s.name  AS table_schema,
               t.name  AS table_name,
               c.name  AS column_name,
               p.value AS comment
        FROM sys.extended_properties p
                 JOIN sys.objects t ON t.object_id = p.major_id
                 JOIN sys.sysusers s ON s.uid = t.schema_id
                 LEFT OUTER JOIN sys.columns c ON c.object_id = p.major_id AND c.column_id = p.minor_id
        WHERE p.class = 1
          AND p.name = 'MS_Description'
          AND p.value IS NOT NULL
          AND t.type IN ('S', 'IT', 'U', 'V')
          AND ${scopeFilter('s.name', schema, 't.name', entity)};`, [], 'getComments'
    ).catch(handleError(`Failed to get comments`, [], {logger, ignoreErrors}))
}

type RawForeignKeyColumn = {
    constraint_name: string
    column_index: number
    src_schema: string
    src_table: string
    src_column: string
    ref_schema: string
    ref_table: string
    ref_column: string
}

const getForeignKeyColumns = ({schema, entity, logger, ignoreErrors}: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawForeignKeyColumn[]> => {
    return conn.query<RawForeignKeyColumn>(`
        SELECT obj.name                 AS constraint_name,
               fkc.constraint_column_id AS column_index,
               sch1.name                AS src_schema,
               tab1.name                AS src_table,
               col1.name                AS src_column,
               sch2.name                AS ref_schema,
               tab2.name                AS ref_table,
               col2.name                AS ref_column
        FROM sys.foreign_key_columns fkc
                 JOIN sys.objects obj ON obj.object_id = fkc.constraint_object_id
                 JOIN sys.tables tab1 ON tab1.object_id = fkc.parent_object_id
                 JOIN sys.schemas sch1 ON tab1.schema_id = sch1.schema_id
                 JOIN sys.columns col1 ON col1.column_id = parent_column_id AND col1.object_id = tab1.object_id
                 JOIN sys.tables tab2 ON tab2.object_id = fkc.referenced_object_id
                 JOIN sys.schemas sch2 ON tab2.schema_id = sch2.schema_id
                 JOIN sys.columns col2 ON col2.column_id = referenced_column_id AND col2.object_id = tab2.object_id
        WHERE ${scopeFilter('sch1.name', schema, 'tab1.name', entity)};`, [], 'getForeignKeyColumns'
    ).catch(handleError(`Failed to get foreign keys`, [], {logger, ignoreErrors}))
}

function buildRelation(columns: RawForeignKeyColumn[]): Relation {
    const first = columns[0]
    return removeUndefined({
        name: first.constraint_name,
        kind: undefined,
        origin: undefined,
        src: { schema: first.src_schema, entity: first.src_table },
        ref: { schema: first.ref_schema, entity: first.ref_table },
        attrs: columns.map(c => ({src: [c.src_column], ref: [c.ref_column]})),
        polymorphic: undefined,
        doc: undefined,
        extra: undefined
    })
}

const getJsonColumns = (columns: Record<EntityId, RawColumn[]>, checks: Record<EntityId, RawCheck[]>, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<Record<EntityId, Record<AttributeName, ValueSchema>>> => {
    return mapEntriesAsync(columns, async (entityId, tableCols) => {
        const ref = parseEntityRef(entityId)
        const jsonCols = tableCols.filter(col => col.column_type === 'nvarchar' && checks[entityId]?.find(ck => ck.column_name == col.column_name && ck.definition?.includes('isjson')))
        return mapValuesAsync(Object.fromEntries(jsonCols.map(c => [c.column_name, c.column_name])), c => inferColumnSchema(ref, [c], opts)(conn))
    })
}

const inferColumnSchema = (ref: EntityRef, attribute: AttributePath, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<ValueSchema> => {
    const sqlTable = buildSqlTable(ref)
    const sqlColumn = buildSqlColumn(attribute)
    const sampleSize = opts.sampleSize || connectorSchemaOptsDefaults.sampleSize
    return conn.query<{value: string}>(`SELECT TOP ${sampleSize} ${sqlColumn} AS value FROM ${sqlTable} WHERE ${sqlColumn} IS NOT NULL;`, [], 'inferColumnSchema')
        .then(rows => valuesToSchema(rows.map(row => safeJsonParse(row.value))))
        .catch(handleError(`Failed to infer schema for column '${formatAttributeRef({...ref, attribute})}'`, valuesToSchema([]), opts))
}
