import {indexBy} from "@azimutt/utils";
import {AttributeRef, QueryResults} from "@azimutt/database-model";
import {Conn, QueryResultArrayMode, QueryResultField} from "./types";

export const execQuery = (query: string, parameters: any[]) => (conn: Conn): Promise<QueryResults> => {
    return conn.queryArrayMode(query, parameters).then(result => buildResults(conn, query, result))
}

async function buildResults(conn: Conn, query: string, result: QueryResultArrayMode): Promise<QueryResults> {
    const tableIds = [...new Set(result.fields.map(f => f.tableID))]
    const columnInfos = await getColumnInfos(conn, tableIds)
    const attributes = buildAttributes(result.fields, columnInfos)
    return {
        query,
        attributes,
        rows: result.rows.map(row => attributes.reduce((acc, col, i) => ({...acc, [col.name]: row[i]}), {}))
    }
}

function buildAttributes(fields: QueryResultField[], columnInfos: ColumnInfo[]): { name: string, ref?: AttributeRef }[] {
    const keys: { [key: string]: true } = {}
    const indexed = indexBy(columnInfos, i => `${i.table_id}-${i.column_id}`)
    return fields.map(f => {
        const name = uniqueName(f.name, keys)
        keys[name] = true
        const info = indexed[`${f.tableID}-${f.columnID}`]
        return info ? {name, ref: {schema: info.schema_name, entity: info.table_name, attribute: [info.column_name]}} : {name}
    })
}

type ColumnInfo = {
    schema_id: number,
    schema_name: string,
    table_id: number,
    table_name: string,
    column_id: number,
    column_name: string,
    type_id: number,
    type_name: string
}

async function getColumnInfos(conn: Conn, tableIds: number[]): Promise<ColumnInfo[]> {
    if (tableIds.length > 0) {
        return conn.query<ColumnInfo>(`
            SELECT n.oid     as schema_id,
                   n.nspname as schema_name,
                   c.oid     as table_id,
                   c.relname as table_name,
                   a.attnum  as column_id,
                   a.attname as column_name,
                   t.oid     as type_id,
                   t.typname as type_name
            FROM pg_attribute a
                     JOIN pg_class c ON c.oid = a.attrelid
                     JOIN pg_namespace n ON n.oid = c.relnamespace
                     JOIN pg_type t ON t.oid = a.atttypid
            WHERE a.attrelid IN (${tableIds.join(', ')})
              AND a.attnum > 0;`)
    } else {
        return []
    }
}

function uniqueName(name: string, currentNames: { [key: string]: true }, cpt: number = 1): string {
    const newName = cpt === 1 ? name : `${name}_${cpt}`
    if (currentNames[newName]) {
        return uniqueName(name, currentNames, cpt + 1)
    } else {
        return newName
    }
}
