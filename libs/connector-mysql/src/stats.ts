import {shuffle} from "@azimutt/utils";
import {
    ColumnCommonValue,
    ColumnName,
    ColumnRef,
    ColumnStats,
    ColumnType,
    ColumnValue,
    parseTableId,
    SchemaName,
    TableId,
    TableName,
    TableSampleValues,
    TableStats
} from "@azimutt/database-types";
import {Conn} from "./common";

export const getTableStats = (id: TableId) => async (conn: Conn): Promise<TableStats> => {
    const {schema, table} = parseTableId(id)
    const sqlTable = `${schema ? `${schema}.` : ''}${table}`
    const rows = await countRows(conn, sqlTable)
    const sample_values = await sampleValues(conn, sqlTable)
    return {schema, table, rows, sample_values}
}

export const getColumnStats = (ref: ColumnRef) => async (conn: Conn): Promise<ColumnStats> => {
    const {schema, table} = parseTableId(ref.table)
    const sqlTable = `${schema ? `${schema}.` : ''}${table}`
    const type = await getColumnType(conn, schema, table, ref.column)
    const basics = await columnBasics(conn, sqlTable, ref.column)
    const common_values = await commonValues(conn, sqlTable, ref.column)
    return {schema, table, column: ref.column, type, ...basics, common_values}
}

async function countRows(conn: Conn, sqlTable: string): Promise<number> {
    const sql = `SELECT count(*) as count FROM ${sqlTable}`
    const rows = await conn.query<{ count: number }>(sql)
    return rows[0].count
}

async function sampleValues(conn: Conn, sqlTable: string): Promise<TableSampleValues> {
    // take several raws to minimize empty columns and randomize samples from several raws
    const sql = `SELECT * FROM ${sqlTable} LIMIT 10`
    const result = await conn.queryArrayMode(sql)
    const samples = await Promise.all(result.fields.map(async (field, fieldIndex) => {
        const values = shuffle(result.rows.map(row => row[fieldIndex]).filter(v => !!v))
        const value = await (values.length > 0 ? Promise.resolve(values[0]) : sampleValue(conn, sqlTable, field.name))
        return [field.name, value] as [string, ColumnValue]
    }))
    return Object.fromEntries(samples)
}

async function sampleValue(conn: Conn, sqlTable: string, column: ColumnName): Promise<ColumnValue> {
    // select several raws to and then shuffle results to avoid showing samples from the same raw
    const sql = `SELECT ${column} as value FROM ${sqlTable} WHERE ${column} IS NOT NULL LIMIT 10`
    const rows = await conn.query<{ value: ColumnValue }>(sql)
    return rows.length > 0 ? shuffle(rows)[0].value : null
}

async function getColumnType(conn: Conn, schema: SchemaName, table: TableName, column: ColumnName): Promise<ColumnType> {
    const rows = await conn.query<{ type: string }>(`
        SELECT COLUMN_TYPE as type
        FROM information_schema.COLUMNS
        WHERE ${schema ? 'TABLE_SCHEMA=? AND ' : ''}TABLE_NAME = ?
          AND COLUMN_NAME = ?;`, schema ? [schema, table, column] : [table, column])
    return rows.length > 0 ? rows[0].type : 'unknown'
}

type ColumnBasics = { rows: number, nulls: number, cardinality: number }

async function columnBasics(conn: Conn, sqlTable: string, column: ColumnName): Promise<ColumnBasics> {
    const rows = await conn.query<ColumnBasics>(`
        SELECT count(*)                                                   AS rows
             , (SELECT count(*) FROM ${sqlTable} WHERE ${column} IS NULL) AS nulls
             , count(distinct ${column})                                  AS cardinality
        FROM ${sqlTable}`)
    return rows[0]
}

function commonValues(conn: Conn, sqlTable: string, column: ColumnName): Promise<ColumnCommonValue[]> {
    const sql = `SELECT ${column} as value, count(*) as count FROM ${sqlTable} GROUP BY ${column} ORDER BY count(*) DESC LIMIT 10`
    return conn.query<ColumnCommonValue>(sql)
}
