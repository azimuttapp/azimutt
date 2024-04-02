import {QueryResults} from "@azimutt/database-model";
import {Conn, QueryResultArrayMode} from "./connect";

export const execQuery = (query: string, parameters: any[]) => (conn: Conn): Promise<QueryResults> => {
    return conn.queryArrayMode(query, parameters).then(result => buildResults(conn, query, result))
}

async function buildResults(conn: Conn, query: string, result: QueryResultArrayMode): Promise<QueryResults> {
    return QueryResults.parse({
        query,
        attributes: result.fields.map(f => ({name: f.name})),
        rows: result.rows.map(row => result.fields.reduce((acc, col, i) => ({...acc, [col.name]: row[i]}), {}))
    })
}
