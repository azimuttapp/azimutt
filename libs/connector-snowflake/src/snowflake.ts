import {groupBy, removeEmpty, removeUndefined} from "@azimutt/utils";
import {
    Attribute,
    ConnectorSchemaOpts,
    Database,
    Entity,
    EntityId,
    formatEntityRef,
    PrimaryKey,
    Relation
} from "@azimutt/database-model";
import {handleError, scopeFilter, scopeMatch} from "./helpers";
import {Conn} from "./connect";

export const getSchema = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<Database> => {
    // access system tables only
    const tables: RawTable[] = await getTables(opts)(conn)
    // TODO: include views? (SELECT * FROM INFORMATION_SCHEMA.VIEWS;)
    const columns: Record<EntityId, RawColumn[]> = await getColumns(opts)(conn).then(groupByEntity)
    const primaryKeyColumns: Record<EntityId, RawPrimaryKeyColumn[]> = await getPrimaryKeyColumns(opts)(conn).then(pks => groupBy(pks, pk => formatEntityRef({catalog: pk.database_name, schema: pk.schema_name, entity: pk.table_name})))
    const foreignKeyColumns: Record<string, RawForeignKeyColumn[]> = await getForeignKeyColumns(opts)(conn).then(fks => groupBy(fks, fk => fk.fk_name))
    // access table data when options are requested
    // TODO: json columns, polymorphic relations...
    // build the database
    return removeUndefined({
        entities: tables.map(table => [toEntityId(table), table] as const).map(([id, table]) => buildEntity(
            table,
            columns[id] || [],
            primaryKeyColumns[id] || [],
        )),
        relations: Object.values(foreignKeyColumns).map(buildRelation),
        types: undefined,
        doc: undefined,
        stats: undefined,
        extra: undefined,
    })
}

// 👇️ Private functions, exported only for tests
// If you use them, beware of breaking changes!

const toEntityId = <T extends { table_catalog: string, table_schema: string, table_name: string }>(value: T): EntityId => formatEntityRef({catalog: value.table_catalog, schema: value.table_schema, entity: value.table_name})
const groupByEntity = <T extends { table_catalog: string, table_schema: string, table_name: string }>(values: T[]): Record<EntityId, T[]> => groupBy(values, toEntityId)

export type RawTable = {
    table_catalog: string
    table_schema: string
    table_name: string
    table_kind: 'BASE TABLE' | 'VIEW'
    table_comment: string | null
    clustering_key: string | null
    table_rows: number
    table_size: number
}

export const getTables = ({catalog, schema, entity, logger, ignoreErrors}: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawTable[]> => {
    return conn.query<RawTable>(`
        SELECT TABLE_CATALOG  AS table_catalog
             , TABLE_SCHEMA   AS table_schema
             , TABLE_NAME     AS table_name
             , TABLE_TYPE     AS table_kind
             , COMMENT        AS table_comment
             , CLUSTERING_KEY AS clustering_key
             , ROW_COUNT      AS table_rows
             , BYTES          AS table_size
        FROM INFORMATION_SCHEMA.TABLES
        WHERE ${scopeFilter('TABLE_CATALOG', catalog,'TABLE_SCHEMA', schema, 'TABLE_NAME', entity)};`, [], 'getTables'
    ).catch(handleError(`Failed to get tables`, [], {logger, ignoreErrors}))
}

function buildEntity(table: RawTable, columns: RawColumn[], primaryKeyColumns: RawPrimaryKeyColumn[]): Entity {
    return removeEmpty({
        catalog: table.table_catalog,
        schema: table.table_schema,
        name: table.table_name,
        kind: table.table_kind === 'BASE TABLE' ? undefined : 'view' as const,
        def: undefined,
        attrs: columns.map(buildAttribute),
        pk: primaryKeyColumns.length > 0 ? buildPrimaryKey(primaryKeyColumns) : undefined,
        indexes: undefined,
        checks: undefined,
        doc: table.table_comment || undefined,
        stats: removeUndefined({
            rows: table.table_rows,
            size: table.table_size,
            sizeIdx: undefined,
            sizeToast: undefined,
            sizeToastIdx: undefined,
            seq_scan: undefined,
            idx_scan: undefined
        }),
        extra: undefined
    })
}

export type RawColumn = {
    table_catalog: string
    table_schema: string
    table_name: string
    column_index: number
    column_name: string
    column_type: string
    column_nullable: 'YES' | 'NO'
    column_default: string | null
    column_comment: string | null
}

export const getColumns = ({catalog, schema, entity, logger, ignoreErrors}: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawColumn[]> => {
    return conn.query<RawColumn>(`
        SELECT TABLE_CATALOG    AS table_catalog
             , TABLE_SCHEMA     AS table_schema
             , TABLE_NAME       AS table_name
             , ORDINAL_POSITION AS column_index
             , COLUMN_NAME      AS column_name
             , DATA_TYPE        AS column_type
             , IS_NULLABLE      AS column_nullable
             , COLUMN_DEFAULT   AS column_default
             , COMMENT          AS column_comment
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE ${scopeFilter('TABLE_CATALOG', catalog,'TABLE_SCHEMA', schema, 'TABLE_NAME', entity)};`, [], 'getColumns'
    ).catch(handleError(`Failed to get columns`, [], {logger, ignoreErrors}))
}

function buildAttribute(column: RawColumn): Attribute {
    return removeUndefined({
        name: column.column_name,
        type: column.column_type,
        nullable: column.column_nullable === 'YES' ? true : undefined,
        generated: undefined,
        default: column.column_default || undefined,
        values: undefined,
        attrs: undefined,
        doc: column.column_comment || undefined,
        stats: undefined,
        extra: undefined
    })
}

export type RawPrimaryKeyColumn = {
    database_name: string // same as `table_catalog`
    schema_name: string
    table_name: string
    column_name: string
    key_sequence: number
    constraint_name: string
    rely: string // 'false'
    comment: string | null
}

export const getPrimaryKeyColumns = ({catalog, schema, entity, logger, ignoreErrors}: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawPrimaryKeyColumn[]> => {
    return conn.query<RawPrimaryKeyColumn>(`SHOW PRIMARY KEYS;`, [], 'getPrimaryKeys') // can't filter on schema only (needs then db too :/)
        .then(keys => keys.filter(key =>
            (catalog ? scopeMatch(key.database_name, catalog) : true) &&
            (schema ? scopeMatch(key.schema_name, schema) : key.schema_name !== 'INFORMATION_SCHEMA') &&
            (entity ? scopeMatch(key.table_name, entity) : true)
        )).catch(handleError(`Failed to get primary keys`, [], {logger, ignoreErrors}))
}

function buildPrimaryKey(columns: RawPrimaryKeyColumn[]): PrimaryKey {
    const pk = columns[0]
    return removeUndefined({
        name: pk.constraint_name,
        attrs: columns.slice(0)
            .sort((a, b) => a.key_sequence - b.key_sequence)
            .map(c => [c.column_name]),
        doc: pk.comment || undefined,
        stats: undefined,
        extra: undefined
    })
}

export type RawForeignKeyColumn = {
    pk_database_name: string
    pk_schema_name: string
    pk_table_name: string
    pk_column_name: string
    fk_database_name: string
    fk_schema_name: string
    fk_table_name: string
    fk_column_name: string
    key_sequence: number
    update_rule: string // 'NO ACTION'
    delete_rule: string // 'NO ACTION'
    fk_name: string
    pk_name: string
    deferrability: string // 'NOT DEFERRABLE'
    rely: string // 'false'
    comment: string | null
}

export const getForeignKeyColumns = ({catalog, schema, entity, logger, ignoreErrors}: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawForeignKeyColumn[]> => {
    return conn.query<RawForeignKeyColumn>(`SHOW EXPORTED KEYS;`, [], 'getForeignKeys') // can't filter on schema only (needs then db too :/)
        .then(keys => keys.filter(key =>
            (catalog ? scopeMatch(key.fk_database_name, catalog) : true) &&
            (schema ? scopeMatch(key.fk_schema_name, schema) : key.fk_schema_name !== 'INFORMATION_SCHEMA') &&
            (entity ? scopeMatch(key.fk_table_name, entity) : true)
        )).catch(handleError(`Failed to get foreign keys${schema ? ` for schema '${schema}'` : ''}`, [], {logger, ignoreErrors}))
}

function buildRelation(columns: RawForeignKeyColumn[]): Relation {
    const rel = columns[0]
    return removeUndefined({
        name: rel.fk_name,
        kind: undefined,
        origin: undefined,
        src: {catalog: rel.fk_database_name, schema: rel.fk_schema_name, entity: rel.fk_table_name},
        ref: {catalog: rel.pk_database_name, schema: rel.pk_schema_name, entity: rel.pk_table_name},
        attrs: columns.slice(0)
            .sort((a, b) => a.key_sequence - b.key_sequence)
            .map(r => ({src: [r.fk_column_name], ref: [r.pk_column_name]})),
        polymorphic: undefined,
        doc: rel.comment || undefined,
        extra: undefined
    })
}
