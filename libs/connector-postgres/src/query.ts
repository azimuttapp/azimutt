import {indexBy} from "@azimutt/utils";
import {AttributeValue, buildQueryAttributes, QueryField, QueryResults} from "@azimutt/models";
import {Conn, QueryResultArrayMode} from "./connect";

export const execQuery = (query: string, parameters: any[]) => (conn: Conn): Promise<QueryResults> => {
    return conn.queryArrayMode(query, parameters).then(result => buildResults(conn, query, result))
}

async function buildResults(conn: Conn, query: string, result: QueryResultArrayMode): Promise<QueryResults> {
    const tableIds = [...new Set(result.fields.map(f => f.tableID))]
    const columnInfos = await getColumnInfos(conn, tableIds)
    const indexed = indexBy(columnInfos, i => `${i.table_id}-${i.column_id}`)
    const fields: QueryField[] = result.fields.map(field => {
        const info = indexed[`${field.tableID}-${field.columnID}`]
        return info ? {name: field.name, schema: info.schema_name, table: info.table_name, column: info.column_name, type: info.type_name} : {name: field.name}
    })
    const attributes = buildQueryAttributes(fields, query)
    const rows = result.rows.map(row => attributes.reduce((acc, col, i) => ({...acc, [col.name]: buildValue(row[i])}), {}))
    return {query, attributes, rows}
}

function buildValue(v: AttributeValue): AttributeValue {
    if (v !== null && typeof v === 'object' && v.constructor.name === 'Buffer') return v.toString()
    return v
}

type ColumnInfo = {
    schema_id: number
    schema_name: string
    table_id: number
    table_name: string
    column_id: number
    column_name: string
    type_id: number
    type_name: string
}

async function getColumnInfos(conn: Conn, tableIds: number[]): Promise<ColumnInfo[]> {
    if (tableIds.length > 0) {
        return conn.query<ColumnInfo>(`
            SELECT n.oid     AS schema_id
                 , n.nspname AS schema_name
                 , c.oid     AS table_id
                 , c.relname AS table_name
                 , a.attnum  AS column_id
                 , a.attname AS column_name
                 , t.oid     AS type_id
                 , t.typname AS type_name
            FROM pg_attribute a
                     JOIN pg_class c ON c.oid = a.attrelid
                     JOIN pg_namespace n ON n.oid = c.relnamespace
                     JOIN pg_type t ON t.oid = a.atttypid
            WHERE a.attrelid IN (${tableIds.join(', ')}) AND a.attnum > 0;`, [], 'getColumnInfos')
    } else {
        return []
    }
}
