import {Connection, RowDataPacket} from "mysql2/promise";
import {shuffle} from "@azimutt/utils";
import {
    ColumnCommonValue,
    ColumnName,
    ColumnRef,
    ColumnStats,
    ColumnType,
    ColumnValue,
    DatabaseUrlParsed,
    parseTableId,
    SchemaName,
    TableId,
    TableName,
    TableSampleValues,
    TableStats
} from "@azimutt/database-types";
import {connect, query} from "./connect";

export async function getTableStats(application: string, url: DatabaseUrlParsed, id: TableId): Promise<TableStats> {
    return await connect(application, url, async conn => {
        const {schema, table} = parseTableId(id)
        const sqlTable = `${schema ? `${schema}.` : ''}${table}`
        const rows = await countRows(conn, sqlTable)
        const sample_values = await sampleValues(conn, sqlTable)
        return {schema, table, rows, sample_values}
    })
}

export async function getColumnStats(application: string, url: DatabaseUrlParsed, ref: ColumnRef): Promise<ColumnStats> {
    return await connect(application, url, async conn => {
        const {schema, table} = parseTableId(ref.table)
        const sqlTable = `${schema ? `${schema}.` : ''}${table}`
        const type = await getColumnType(conn, schema, table, ref.column)
        const basics = await columnBasics(conn, sqlTable, ref.column)
        const common_values = await commonValues(conn, sqlTable, ref.column)
        return {schema, table, column: ref.column, type, ...basics, common_values}
    })
}

async function countRows(conn: Connection, sqlTable: string): Promise<number> {
    const sql = `SELECT count(*) as count FROM ${sqlTable}`
    const res = await query<{ count: number }>(conn, sql)
    return res[0].count
}

async function sampleValues(conn: Connection, sqlTable: string): Promise<TableSampleValues> {
    // take several raws to minimize empty columns and randomize samples from several raws
    const sql = `SELECT * FROM ${sqlTable} LIMIT 10`
    const [rows, fields] = await conn.query<RowDataPacket[][]>({sql, rowsAsArray: true})
    const samples = await Promise.all(fields.map(async (field, fieldIndex) => {
        const values = shuffle(rows.map(r => r[fieldIndex]).filter(v => !!v))
        const value = await (values.length > 0 ? Promise.resolve(values[0]) : sampleValue(conn, sqlTable, field.name))
        return [field.name, value] as [string, any]
    }))
    return Object.fromEntries(samples)
}

async function sampleValue(conn: Connection, sqlTable: string, column: ColumnName): Promise<ColumnValue> {
    // select several raws to and then shuffle results to avoid showing samples from the same raw
    const sql = `SELECT ${column} as value FROM ${sqlTable} WHERE ${column} IS NOT NULL LIMIT 10`
    const rows = await query<{ value: any }>(conn, sql)
    return rows.length > 0 ? shuffle(rows)[0].value : null
}

async function getColumnType(conn: Connection, schema: SchemaName, table: TableName, column: ColumnName): Promise<ColumnType> {
    const rows = await query<{ type: string }>(conn, `SELECT COLUMN_TYPE as type
                                                      FROM information_schema.COLUMNS
                                                      WHERE ${schema ? 'TABLE_SCHEMA=? AND ' : ''}TABLE_NAME = ?
                                                        AND COLUMN_NAME = ?;`, schema ? [schema, table, column] : [table, column])
    return rows.length > 0 ? rows[0].type : 'unknown'
}

type ColumnBasics = { rows: number, nulls: number, cardinality: number }

async function columnBasics(conn: Connection, sqlTable: string, column: ColumnName): Promise<ColumnBasics> {
    const rows = await query<ColumnBasics>(conn, `
        SELECT count(*)                                                   AS rows
             , (SELECT count(*) FROM ${sqlTable} WHERE ${column} IS NULL) AS nulls
             , count(distinct ${column})                                  AS cardinality
        FROM ${sqlTable}`)
    return rows[0]
}

function commonValues(conn: Connection, sqlTable: string, column: ColumnName): Promise<ColumnCommonValue[]> {
    const sql = `SELECT ${column} as value, count(*) as count FROM ${sqlTable} GROUP BY ${column} ORDER BY count(*) DESC LIMIT 10`
    return query<ColumnCommonValue>(conn, sql)
}
