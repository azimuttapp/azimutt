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
    const res = await conn.query<{ COUNT: number }>(`SELECT count(*) AS COUNT FROM ${sqlTable}`, [], 'countRows');
    return Number(res[0].COUNT);
}

async function getSampleValues(conn: Conn, sqlTable: SqlFragment): Promise<{ [attribute: string]: AttributeValue }> {
    // take several raws to minimize empty columns and randomize samples from several raws
    const result = await conn.queryArrayMode(`SELECT * FROM ${sqlTable} FETCH FIRST 10 ROWS ONLY;`, [], 'getSampleValues')
    const samples = await Promise.all(result.fields.map(async (field, fieldIndex) => {
        const values = shuffle(result.rows.map((row) => row[fieldIndex]).filter((v) => !!v))
        const value = await (values.length > 0 ? Promise.resolve(values[0]) : getSampleValue(conn, sqlTable, buildSqlColumn([field.name])))
        return [field.name, value] as [string, AttributeValue]
    }))
    return Object.fromEntries(samples)
}

async function getSampleValue(conn: Conn, sqlTable: SqlFragment, sqlColumn: SqlFragment): Promise<AttributeValue> {
    // select several raws to and then shuffle results to avoid showing samples from the same raw
    const rows = await conn.query(`
        SELECT ${sqlColumn} AS value
        FROM ${sqlTable}
        WHERE ${sqlColumn} IS NOT NULL FETCH FIRST 10 ROWS ONLY`, [], 'getSampleValue')
    return rows.length > 0 ? shuffle(rows)[0][0] : null
}

async function getColumnType(conn: Conn, ref: AttributeRef): Promise<AttributeType> {
    const rows = await conn.query<{FORMATTED_TYPE: string}>(`
        SELECT CASE
                   WHEN data_type IN ('VARCHAR2', 'CHAR') THEN data_type || '(' || data_length || ')'
                   WHEN data_type IN ('NUMBER') THEN data_type || '(' || data_precision || ', ' || data_scale || ')'
                   ELSE data_type
                   END AS FORMATTED_TYPE
        FROM ALL_TAB_COLUMNS
        WHERE TABLE_NAME = :table_name
          AND COLUMN_NAME = :column_name ${ref.schema ? ` AND OWNER = :owner` : ""}`, [ref.entity, ref.attribute[0], ref.schema].filter(Boolean), 'getColumnType')
    return rows.length > 0 ? (rows[0].FORMATTED_TYPE as string) : 'unknown'
}

type ColumnBasics = { rows: number; nulls: number; cardinality: number }

async function getColumnBasics(conn: Conn, sqlTable: SqlFragment, sqlColumn: SqlFragment): Promise<ColumnBasics> {
    const [rows, nulls, cardinality] = await Promise.all([
        [`SELECT count(*) AS COUNT FROM ${sqlTable}`, 'countRows'],
        [`SELECT count(*) AS COUNT FROM ${sqlTable} t WHERE t.${sqlColumn} IS NULL`, 'countNulls'],
        [`SELECT count(distinct t.${sqlColumn}) AS COUNT FROM ${sqlTable} t`, 'countDistincts'],
    ].map(([query, name]) => conn.query<{ COUNT: number }>(query, [], name).then(res => Number(res[0].COUNT))))
    return {rows, nulls, cardinality}
}

async function getCommonValues(conn: Conn, sqlTable: SqlFragment, sqlColumn: SqlFragment): Promise<ConnectorAttributeStatsValue[]> {
    return await conn.query<{ VALUE: AttributeValue, COUNT: number }>(`
        SELECT t.${sqlColumn} AS VALUE, count(*) AS COUNT
        FROM ${sqlTable} t
        GROUP BY t.${sqlColumn}
        ORDER BY count(*) DESC FETCH FIRST 10 ROWS ONLY`, [], 'getCommonValues'
    ).then(res => res.map(r => ({value: r.VALUE, count: r.COUNT})))
}
