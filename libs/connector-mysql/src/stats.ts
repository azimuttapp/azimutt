import {shuffle} from "@azimutt/utils";
import {Conn} from "./common";
import {
    AttributeName,
    AttributeRef,
    AttributeType,
    AttributeValue,
    ConnectorAttributeStats,
    ConnectorAttributeStatsValue,
    ConnectorEntityStats,
    EntityRef,
    SqlFragment
} from "@azimutt/database-model";
import {buildSqlColumn, buildSqlTable} from "./helpers";

export const getTableStats = (ref: EntityRef) => async (conn: Conn): Promise<ConnectorEntityStats> => {
    const sqlTable = buildSqlTable(ref)
    const rows = await countRows(conn, sqlTable)
    const sampleValues = await getSampleValues(conn, sqlTable)
    return {...ref, rows, sampleValues}
}

export const getColumnStats = (ref: AttributeRef) => async (conn: Conn): Promise<ConnectorAttributeStats> => {
    const sqlTable = buildSqlTable(ref)
    const sqlColumn = buildSqlColumn(ref.attribute)
    const type = await getColumnType(conn, ref)
    const basics = await getColumnBasics(conn, sqlTable, sqlColumn)
    const commonValues = await getCommonValues(conn, sqlTable, sqlColumn)
    return {...ref, type, ...basics, commonValues}
}

async function countRows(conn: Conn, sqlTable: SqlFragment): Promise<number> {
    const sql = `SELECT count(*) as count FROM ${sqlTable};`
    const rows = await conn.query<{ count: number }>(sql)
    return rows[0].count
}

async function getSampleValues(conn: Conn, sqlTable: SqlFragment): Promise<{ [attribute: string]: AttributeValue }> {
    // take several raws to minimize empty columns and randomize samples from several raws
    const sql = `SELECT * FROM ${sqlTable} LIMIT 10;`
    const result = await conn.queryArrayMode(sql)
    const samples = await Promise.all(result.fields.map(async (field, fieldIndex) => {
        const values = shuffle(result.rows.map(row => row[fieldIndex]).filter(v => !!v))
        const value = await (values.length > 0 ? Promise.resolve(values[0]) : getSampleValue(conn, sqlTable, field.name))
        return [field.name, value] as [string, AttributeValue]
    }))
    return Object.fromEntries(samples)
}

async function getSampleValue(conn: Conn, sqlTable: SqlFragment, column: AttributeName): Promise<AttributeValue> {
    // select several raws to and then shuffle results to avoid showing samples from the same raw
    const sql = `SELECT ${column} as value FROM ${sqlTable} WHERE ${column} IS NOT NULL LIMIT 10;`
    const rows = await conn.query<{ value: AttributeValue }>(sql)
    return rows.length > 0 ? shuffle(rows)[0].value : null
}

async function getColumnType(conn: Conn, ref: AttributeRef): Promise<AttributeType> {
    const rows = await conn.query<{ type: string }>(`
        SELECT COLUMN_TYPE as type
        FROM information_schema.COLUMNS
        WHERE ${ref.schema ? 'TABLE_SCHEMA=? AND ' : ''}TABLE_NAME = ?
          AND COLUMN_NAME = ?;`, (ref.schema ? [ref.schema] : []).concat([ref.entity, ref.attribute[0]]))
    return rows.length > 0 ? rows[0].type : 'unknown'
}

type ColumnBasics = { rows: number, nulls: number, cardinality: number }

async function getColumnBasics(conn: Conn, sqlTable: SqlFragment, sqlColumn: SqlFragment): Promise<ColumnBasics> {
    const rows = await conn.query<ColumnBasics>(`
        SELECT count(*)                                                      AS rows
             , (SELECT count(*) FROM ${sqlTable} WHERE ${sqlColumn} IS NULL) AS nulls
             , count(distinct ${sqlColumn})                                  AS cardinality
        FROM ${sqlTable};`)
    return rows[0]
}

function getCommonValues(conn: Conn, sqlTable: SqlFragment, sqlColumn: SqlFragment): Promise<ConnectorAttributeStatsValue[]> {
    const sql = `SELECT ${sqlColumn} as value, count(*) as count FROM ${sqlTable} GROUP BY ${sqlColumn} ORDER BY count(*) DESC LIMIT 10;`
    return conn.query<ConnectorAttributeStatsValue>(sql)
}
