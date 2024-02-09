import {groupBy, Logger, removeUndefined, sequence, zip} from "@azimutt/utils";
import {AzimuttSchema, ColumnName, SchemaName, TableName} from "@azimutt/database-types";
import {schemaToColumns, ValueSchema, valuesToSchema} from "@azimutt/json-infer-schema";
import {Conn} from "./common";
import {buildSqlColumn, buildSqlTable} from "./helpers";

export type SnowflakeSchema = { tables: SnowflakeTable[], relations: SnowflakeRelation[], types: SnowflakeType[] }
export type SnowflakeTable = { catalog: SnowflakeCatalogName, schema: SnowflakeSchemaName, table: SnowflakeTableName, view: boolean, columns: SnowflakeColumn[], primaryKey: SnowflakePrimaryKey | null, uniques: SnowflakeUnique[], indexes: SnowflakeIndex[], checks: SnowflakeCheck[], comment: string | null }
export type SnowflakeColumn = { name: SnowflakeColumnName, type: SnowflakeColumnType, nullable: boolean, default: string | null, comment: string | null, values: string[] | null, schema: ValueSchema | null }
export type SnowflakePrimaryKey = { name: string | null, columns: SnowflakeColumnName[] }
export type SnowflakeUnique = { name: string, columns: SnowflakeColumnName[], definition: string | null }
export type SnowflakeIndex = { name: string, columns: SnowflakeColumnName[], definition: string | null }
export type SnowflakeCheck = { name: string, columns: SnowflakeColumnName[], predicate: string | null }
export type SnowflakeRelation = { name: SnowflakeRelationName, src: SnowflakeTableRef, ref: SnowflakeTableRef, comment: string | null }
export type SnowflakeTableRef = { catalog: SnowflakeCatalogName, schema: SnowflakeSchemaName, table: SnowflakeTableName, column: SnowflakeColumnName }
export type SnowflakeColumnLink = { src: SnowflakeColumnName, ref: SnowflakeColumnName }
export type SnowflakeType = { schema: SnowflakeSchemaName, name: SnowflakeTypeName, values: string[] | null }
export type SnowflakeCatalogName = string
export type SnowflakeSchemaName = string
export type SnowflakeTableName = string
export type SnowflakeColumnName = string
export type SnowflakeColumnType = string
export type SnowflakeRelationName = string
export type SnowflakeTypeName = string
export type SnowflakeTableId = `${SnowflakeCatalogName}.${SnowflakeSchemaName}.${SnowflakeTableName}`

export const getSchema = (schema: SnowflakeSchemaName | undefined, sampleSize: number, ignoreErrors: boolean, logger: Logger) => async (conn: Conn): Promise<SnowflakeSchema> => {
    // TODO: include VIEWS? (SELECT * FROM INFORMATION_SCHEMA.VIEWS;)
    const tables = await getTables(conn, schema, ignoreErrors, logger)
    const columns = await getColumns(conn, schema, ignoreErrors, logger).then(cols => groupBy(cols, toTableId))
    const foreignKeys = await getForeignKeys(conn, ignoreErrors, logger)
    return {
        tables: tables.map(table => {
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
                    comment: column.comment,
                    values: null,
                    schema: null
                })),
                primaryKey: null,
                uniques: [],
                indexes: [],
                checks: [],
                comment: table.comment
            }
        }),
        relations: foreignKeys.map(rel => {
            return {
                name: rel.fk_name,
                src: {catalog: rel.fk_database_name, schema: rel.fk_schema_name, table: rel.fk_table_name, column: rel.fk_column_name},
                ref: {catalog: rel.pk_database_name, schema: rel.pk_schema_name, table: rel.pk_table_name, column: rel.pk_column_name},
                comment: rel.comment
            }
        }),
        types: []
    }
}

export function formatSchema(schema: SnowflakeSchema, inferRelations: boolean): AzimuttSchema {
    // FIXME: handle inferRelations
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
                values: c.values && c.values.length > 0 ? c.values : undefined,
                columns: c.schema ? schemaToColumns(c.schema, 0) : undefined
            })),
            view: t.view || undefined,
            primaryKey: undefined,
            uniques: undefined,
            indexes: undefined,
            checks: undefined,
            comment: t.comment || undefined
        })),
        relations: schema.relations.map(r => ({
            name: r.name,
            src: {schema: r.src.schema, table: r.src.table, column: r.src.column},
            ref: {schema: r.ref.schema, table: r.ref.table, column: r.ref.column}
        })),
        types: []
    }
}

// 👇️ Private functions, some are exported only for tests
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

export async function getForeignKeys(conn: Conn, ignoreErrors: boolean, logger: Logger): Promise<RawForeignKey[]> {
    return conn.query<RawForeignKey>(`SHOW EXPORTED KEYS;`) // can't filter on schema only (needs db too :/)
        .catch(handleError(`Failed to get foreign keys`, [], ignoreErrors, logger))
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
