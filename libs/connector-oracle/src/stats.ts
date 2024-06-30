import {shuffle} from "@azimutt/utils";
import {
    AttributeRef,
    AttributeType,
    AttributeValue,
    ConnectorAttributeStats,
    ConnectorAttributeStatsValue,
    ConnectorEntityStats,
    EntityRef,
    SqlFragment,
} from "@azimutt/models";
import {buildSqlColumn, buildSqlTable} from "./helpers";
import {Conn} from "./connect";

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
    const sql = `SELECT count(*) FROM ${sqlTable}`
    const rows = await conn.query(sql)
    return Number(rows[0][0])
}

async function getSampleValues(conn: Conn, sqlTable: SqlFragment): Promise<{ [attribute: string]: AttributeValue }> {
    // take several raws to minimize empty columns and randomize samples from several raws
    const sql = `SELECT * FROM ${sqlTable} FETCH FIRST 10 ROWS ONLY;`
    const result = await conn.queryArrayMode(sql)
    const samples = await Promise.all(result.fields.map(async (field, fieldIndex) => {
        const values = shuffle(result.rows.map((row) => row[fieldIndex]).filter((v) => !!v))
        const value = await (values.length > 0 ? Promise.resolve(values[0]) : getSampleValue(conn, sqlTable, buildSqlColumn([field.name])))
        return [field.name, value] as [string, AttributeValue]
    }))
    return Object.fromEntries(samples)
}

async function getSampleValue(conn: Conn, sqlTable: SqlFragment, sqlColumn: SqlFragment): Promise<AttributeValue> {
    // select several raws to and then shuffle results to avoid showing samples from the same raw
    const sql = `SELECT ${sqlColumn} AS value
                 FROM ${sqlTable}
                 WHERE ${sqlColumn} IS NOT NULL FETCH FIRST 10 ROWS ONLY`
    const rows = await conn.query(sql)
    return rows.length > 0 ? shuffle(rows)[0][0] : null
}

async function getColumnType(conn: Conn, ref: AttributeRef): Promise<AttributeType> {
    const rows = await conn.query(`
        SELECT CASE
                   WHEN data_type IN ('VARCHAR2', 'CHAR') THEN data_type || '(' || data_length || ')'
                   WHEN data_type IN ('NUMBER') THEN data_type || '(' || data_precision || ', ' || data_scale || ')'
                   ELSE data_type
                   END AS formatted_type
        FROM all_tab_columns
        WHERE table_name = :table_name
          AND column_name = :column_name ${ref.schema ? ` AND owner = :owner` : ""}`, [ref.entity, ref.attribute[0], ref.schema].filter(Boolean))
    return rows.length > 0 ? (rows[0][0] as string) : 'unknown'
}

type ColumnBasics = { rows: number; nulls: number; cardinality: number }

async function getColumnBasics(conn: Conn, sqlTable: SqlFragment, sqlColumn: SqlFragment): Promise<ColumnBasics> {
    const queries = [
        `SELECT count(*)
         FROM ${sqlTable}`,
        `SELECT count(*)
         FROM ${sqlTable}
         WHERE ${sqlColumn} IS NULL`,
        `SELECT count(distinct ${sqlColumn})
         FROM ${sqlTable}`,
    ]
    const [rows, nulls, cardinality] = await Promise.all(queries.map((query) => conn.query(query).then((res) => Number(res[0][0]))))
    return {rows, nulls, cardinality}
}

async function getCommonValues(conn: Conn, sqlTable: SqlFragment, sqlColumn: SqlFragment): Promise<ConnectorAttributeStatsValue[]> {
    const sql = `
        SELECT ${sqlColumn} AS value, count(*)
        FROM ${sqlTable}
        GROUP BY ${sqlColumn}
        ORDER BY count(*) DESC FETCH FIRST 10 ROWS ONLY`
    const res = await conn.query(sql)
    return res.reduce<ConnectorAttributeStatsValue[]>((acc, row) => {
        const [value, count] = row as any[]
        acc.push({count, value})
        return acc
    }, [])
}
