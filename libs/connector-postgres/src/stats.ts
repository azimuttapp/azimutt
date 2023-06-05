import {Client} from "pg";
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
    return await connect(application, url, async client => {
        const {schema, table} = parseTableId(id)
        const sqlTable = `${schema ? `${schema}.` : ''}${table}`
        const rows = await countRows(client, sqlTable)
        const sample_values = await sampleValues(client, sqlTable)
        return {schema, table, rows, sample_values}
    })
}

export async function getColumnStats(application: string, url: DatabaseUrlParsed, ref: ColumnRef): Promise<ColumnStats> {
    return await connect(application, url, async client => {
        const {schema, table} = parseTableId(ref.table)
        const sqlTable = `${schema ? `${schema}.` : ''}${table}`
        const type = await getColumnType(client, schema, table, ref.column)
        const basics = await columnBasics(client, sqlTable, ref.column)
        const common_values = await commonValues(client, sqlTable, ref.column)
        return {schema, table, column: ref.column, type, ...basics, common_values}
    })
}

async function countRows(client: Client, sqlTable: string): Promise<number> {
    const sql = `SELECT count(*)::int FROM ${sqlTable}`
    const rows = await query<{ count: number }>(client, sql)
    return rows[0].count
}

async function sampleValues(client: Client, sqlTable: string): Promise<TableSampleValues> {
    // take several raws to minimize empty columns and randomize samples from several raws
    const sql = `SELECT * FROM ${sqlTable} LIMIT 10`
    const res = await client.query(sql)
    const samples = await Promise.all(res.fields.map(async field => {
        const values = shuffle(res.rows.map(r => r[field.name]).filter(v => !!v))
        const value = await (values.length > 0 ? Promise.resolve(values[0]) : sampleValue(client, sqlTable, field.name))
        return [field.name, value] as [string, any]
    }))
    return Object.fromEntries(samples)
}

async function sampleValue(client: Client, sqlTable: string, column: ColumnName): Promise<ColumnValue> {
    // select several raws to and then shuffle results to avoid showing samples from the same raw
    const sql = `SELECT ${column} as value FROM ${sqlTable} WHERE ${column} IS NOT NULL LIMIT 10`
    const rows = await query<{ value: any }>(client, sql)
    return rows.length > 0 ? shuffle(rows)[0].value : null
}

async function getColumnType(client: Client, schema: SchemaName, table: TableName, column: ColumnName): Promise<ColumnType> {
    // category: https://www.postgresql.org/docs/current/catalog-pg-type.html#CATALOG-TYPCATEGORY-TABLE
    const rows = await query<{ formatted: ColumnType, name: string, category: string }>(client, `
        SELECT format_type(a.atttypid, a.atttypmod) AS formatted
             , t.typname                            AS name
             , t.typcategory                        AS category
        FROM pg_attribute a
                 JOIN pg_class c ON c.oid = a.attrelid
                 JOIN pg_namespace n ON n.oid = c.relnamespace
                 JOIN pg_type t ON t.oid = a.atttypid
        WHERE c.relname = $1
          AND a.attname = $2${schema ? ' AND n.nspname=$3' : ''}`, schema ? [table, column, schema] : [table, column])
    return rows.length > 0 ? rows[0].formatted : 'unknown'
}

type ColumnBasics = { rows: number, nulls: number, cardinality: number }

async function columnBasics(client: Client, sqlTable: string, column: ColumnName): Promise<ColumnBasics> {
    const rows = await query<ColumnBasics>(client, `
        SELECT count(*)::int                                                   AS rows
             , (SELECT count(*)::int FROM ${sqlTable} WHERE ${column} IS NULL) AS nulls
             , count(distinct ${column})::int                                  AS cardinality
        FROM ${sqlTable}`)
    return rows[0]
}

function commonValues(client: Client, sqlTable: string, column: ColumnName): Promise<ColumnCommonValue[]> {
    const sql = `SELECT ${column} as value, count(*)::int FROM ${sqlTable} GROUP BY ${column} ORDER BY count(*) DESC LIMIT 10`
    return query<ColumnCommonValue>(client, sql)
}
