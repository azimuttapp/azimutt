import {groupBy, Logger, removeUndefined} from "@azimutt/utils";
import {AzimuttSchema} from "@azimutt/database-types";
import {Conn} from "./common";

export type SnowflakeSchema = { tables: SnowflakeTable[], relations: SnowflakeRelation[] }
export type SnowflakeTable = { catalog: SnowflakeCatalogName, schema: SnowflakeSchemaName, table: SnowflakeTableName, view: boolean, columns: SnowflakeColumn[], primaryKey: SnowflakePrimaryKey | null, comment: string | null }
export type SnowflakeColumn = { name: SnowflakeColumnName, type: SnowflakeColumnType, nullable: boolean, default: string | null, comment: string | null }
export type SnowflakePrimaryKey = { name: string, columns: SnowflakeColumnName[] }
export type SnowflakeRelation = { name: SnowflakeRelationName, src: SnowflakeTableRef, ref: SnowflakeTableRef, columns: SnowflakeColumnLink[], comment: string | null }
export type SnowflakeTableRef = { catalog: SnowflakeCatalogName, schema: SnowflakeSchemaName, table: SnowflakeTableName }
export type SnowflakeColumnLink = { src: SnowflakeColumnName, ref: SnowflakeColumnName }
export type SnowflakeCatalogName = string
export type SnowflakeSchemaName = string
export type SnowflakeTableName = string
export type SnowflakeColumnName = string
export type SnowflakeColumnType = string
export type SnowflakeRelationName = string
export type SnowflakeTableId = `${SnowflakeCatalogName}.${SnowflakeSchemaName}.${SnowflakeTableName}`

export type SnowflakeSchemaOpts = {logger: Logger, schema: SnowflakeSchemaName | undefined, sampleSize: number, inferRelations: boolean, ignoreErrors: boolean}
export const getSchema = ({logger, schema, sampleSize, inferRelations, ignoreErrors}: SnowflakeSchemaOpts) => async (conn: Conn): Promise<SnowflakeSchema> => {
    // TODO: include VIEWS? (SELECT * FROM INFORMATION_SCHEMA.VIEWS;)
    const tables = await getTables(conn, schema, ignoreErrors, logger)
    const columns = await getColumns(conn, schema, ignoreErrors, logger).then(cols => groupBy(cols, toTableId))
    const primaryKeys = await getPrimaryKeys(conn, schema, ignoreErrors, logger).then(keys => groupBy(keys, key => `${key.database_name}.${key.schema_name}.${key.table_name}`))
    const foreignKeys = await getForeignKeys(conn, schema, ignoreErrors, logger).then(keys => groupBy(keys, key => key.fk_name))
    return {
        tables: tables.map(table => {
            const pk = primaryKeys[toTableId(table)]
            return {
                catalog: table.catalog,
                schema: table.schema,
                table: table.table,
                view: table.type === 'VIEW',
                columns: (columns[toTableId(table)] || []).sort((a, b) => a.position - b.position).map(column => ({
                    name: column.column,
                    type: column.type,
                    nullable: column.nullable === 'YES',
                    default: column.default,
                    comment: column.comment
                })),
                primaryKey: pk ? {name: pk[0].constraint_name, columns: pk.sort((a, b) => a.key_sequence - b.key_sequence).map(c => c.column_name)} : null,
                comment: table.comment
            }
        }),
        relations: Object.entries(foreignKeys).map(([name, cols]) => {
            const rels = cols.sort((a, b) => a.key_sequence - b.key_sequence)
            const rel = rels[0]
            return {
                name: name,
                src: {catalog: rel.fk_database_name, schema: rel.fk_schema_name, table: rel.fk_table_name},
                ref: {catalog: rel.pk_database_name, schema: rel.pk_schema_name, table: rel.pk_table_name},
                columns: rels.map(r => ({src: r.fk_column_name, ref: r.pk_column_name})),
                comment: rel.comment
            }
        })
    }
}

export function formatSchema(schema: SnowflakeSchema): AzimuttSchema {
    return {
        tables: schema.tables.map(t => removeUndefined({
            schema: t.schema,
            table: t.table,
            columns: t.columns.map(c => removeUndefined({
                name: c.name,
                type: c.type,
                nullable: c.nullable || undefined,
                default: c.default || undefined,
                comment: c.comment || undefined,
                values: undefined, // TODO
                columns: undefined // TODO
            })),
            view: t.view || undefined,
            primaryKey: t.primaryKey ? removeUndefined({
                name: t.primaryKey.name || undefined,
                columns: t.primaryKey.columns,
            }) : undefined,
            uniques: undefined, // TODO
            indexes: undefined, // TODO
            checks: undefined, // TODO
            comment: t.comment || undefined
        })),
        relations: schema.relations.flatMap(r => r.columns.map(c => ({
            name: r.name,
            src: {schema: r.src.schema, table: r.src.table, column: c.src},
            ref: {schema: r.ref.schema, table: r.ref.table, column: c.ref}
        }))),
        types: []
    }
}

// 👇️ Private functions, exported only for tests
// If you use them, beware of breaking changes!

export type RawTable = {
    catalog: SnowflakeCatalogName
    schema: SnowflakeSchemaName
    table: SnowflakeTableName
    type: 'BASE TABLE' | 'VIEW'
    comment: string | null
    clusteringKey: string | null
    rowCount: number
    size: number
}

export async function getTables(conn: Conn, schema: SnowflakeSchemaName | undefined, ignoreErrors: boolean, logger: Logger): Promise<RawTable[]> {
    return conn.query<RawTable>(`
        SELECT TABLE_CATALOG as "catalog"
             , TABLE_SCHEMA as "schema"
             , TABLE_NAME as "table"
             , TABLE_TYPE as "type"
             , COMMENT as "comment"
             , CLUSTERING_KEY as "clusteringKey"
             , ROW_COUNT as "rowCount"
             , BYTES as "size"
        FROM INFORMATION_SCHEMA.TABLES
        WHERE ${filterSchema('TABLE_SCHEMA', schema)};
    `).catch(handleError(`Failed to get tables${schema ? ` for schema '${schema}'` : ''}`, [], ignoreErrors, logger))
}

export type RawColumn = {
    catalog: SnowflakeCatalogName
    schema: SnowflakeSchemaName
    table: SnowflakeTableName
    column: SnowflakeColumnName
    position: number
    type: string
    nullable: 'YES' | 'NO'
    default: string | null
    comment: string | null
}

export async function getColumns(conn: Conn, schema: SnowflakeSchemaName | undefined, ignoreErrors: boolean, logger: Logger): Promise<RawColumn[]> {
    return conn.query<RawColumn>(`
        SELECT TABLE_CATALOG as "catalog"
             , TABLE_SCHEMA as "schema"
             , TABLE_NAME as "table"
             , COLUMN_NAME as "column"
             , ORDINAL_POSITION as "position"
             , DATA_TYPE as "type"
             , IS_NULLABLE as "nullable"
             , COLUMN_DEFAULT as "default"
             , COMMENT as "comment"
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE ${filterSchema('TABLE_SCHEMA', schema)};
    `).catch(handleError(`Failed to get columns${schema ? ` for schema '${schema}'` : ''}`, [], ignoreErrors, logger))
}

export type RawPrimaryKey = {
    database_name: SnowflakeCatalogName
    schema_name: SnowflakeSchemaName
    table_name: SnowflakeTableName
    column_name: SnowflakeColumnName
    key_sequence: number
    constraint_name: string
    rely: string // 'false'
    comment: string | null
}

export async function getPrimaryKeys(conn: Conn, schema: SnowflakeSchemaName | undefined, ignoreErrors: boolean, logger: Logger): Promise<RawPrimaryKey[]> {
    return conn.query<RawPrimaryKey>(`SHOW PRIMARY KEYS;`) // can't filter on schema only (needs then db too :/)
        .then(keys => keys.filter(key => schema ? key.schema_name === schema : key.schema_name !== 'INFORMATION_SCHEMA'))
        .catch(handleError(`Failed to get primary keys${schema ? ` for schema '${schema}'` : ''}`, [], ignoreErrors, logger))
}

export type RawForeignKey = {
    pk_database_name: SnowflakeCatalogName
    pk_schema_name: SnowflakeSchemaName
    pk_table_name: SnowflakeTableName
    pk_column_name: SnowflakeColumnName
    fk_database_name: SnowflakeCatalogName
    fk_schema_name: SnowflakeSchemaName
    fk_table_name: SnowflakeTableName
    fk_column_name: SnowflakeColumnName
    key_sequence: number
    update_rule: string // 'NO ACTION'
    delete_rule: string // 'NO ACTION'
    fk_name: string
    pk_name: string
    deferrability: string // 'NOT DEFERRABLE'
    rely: string // 'false'
    comment: string | null
}

export async function getForeignKeys(conn: Conn, schema: SnowflakeSchemaName | undefined, ignoreErrors: boolean, logger: Logger): Promise<RawForeignKey[]> {
    return conn.query<RawForeignKey>(`SHOW EXPORTED KEYS;`) // can't filter on schema only (needs then db too :/)
        .then(keys => keys.filter(key => schema ? key.fk_schema_name === schema : key.fk_schema_name !== 'INFORMATION_SCHEMA'))
        .catch(handleError(`Failed to get foreign keys${schema ? ` for schema '${schema}'` : ''}`, [], ignoreErrors, logger))
}

function toTableId<T extends { catalog: SnowflakeCatalogName, schema: SnowflakeSchemaName, table: SnowflakeTableName }>(value: T): SnowflakeTableId {
    return `${value.catalog}.${value.schema}.${value.table}`
}

function filterSchema(field: string, schema: SnowflakeSchemaName | undefined): string {
    return `${field} ${schema ? `= '${schema}'` : `!= 'INFORMATION_SCHEMA'`}`
}

function handleError<T>(msg: string, value: T, ignoreErrors: boolean, logger: Logger) {
    return (err: any): Promise<T> => {
        if (ignoreErrors) {
            logger.warn(`${msg}. Ignoring...`)
            return Promise.resolve(value)
        } else {
            return Promise.reject(err)
        }
    }
}
