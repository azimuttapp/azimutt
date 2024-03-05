import {DatabaseQueryResults} from "@azimutt/database-types";
import {Conn, QueryResultArrayMode} from "./types";

export const execQuery = (query: string, parameters: any[]) => (conn: Conn): Promise<DatabaseQueryResults> => {
    return conn.queryArrayMode(query, parameters).then(result => buildResults(conn, query, result))
}

async function buildResults(conn: Conn, query: string, result: QueryResultArrayMode): Promise<DatabaseQueryResults> {
    return {
        query,
        columns: result.fields.map(f => ({name: f.name})),
        rows: result.rows.map(row => result.fields.reduce((acc, col, i) => ({...acc, [col.name]: row[i]}), {}))
    }
}
