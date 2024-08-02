import {buildQueryAttributes, QueryResults} from "@azimutt/models";
import {Conn, QueryResultArrayMode} from "./connect";

export const execQuery = (query: string, parameters: any[]) => (conn: Conn): Promise<QueryResults> => {
    return conn.queryArrayMode(query, parameters).then(result => buildResults(conn, query, result))
}

async function buildResults(conn: Conn, query: string, result: QueryResultArrayMode): Promise<QueryResults> {
    const attributes = buildQueryAttributes(result.fields.map(f => f.name), query)
    const rows = result.rows.map(row => attributes.reduce((acc, col, i) => ({...acc, [col.name]: row[i]}), {}))
    return {query, attributes, rows}
}
