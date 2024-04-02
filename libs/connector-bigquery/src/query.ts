import {QueryResults} from "@azimutt/database-model";
import {Conn, QueryResultRow} from "./connect"

export const execQuery = (query: string, parameters: any[], name?: string) => (conn: Conn): Promise<QueryResults> => {
    return conn.query(query, parameters, name).then(res => buildResults(query, res))
}

function buildResults(query: string, results: QueryResultRow[]): QueryResults {
    const columns = Object.keys(results[0])
    return QueryResults.parse({
        query,
        attributes: columns.map(name => ({name})), // TODO: parse SQL to infer column ref
        rows: results.map(row => columns.reduce((acc, col) => ({...acc, [col]: row[col]}), {}))
    })
}
