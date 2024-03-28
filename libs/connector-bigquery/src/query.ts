import {DatabaseQueryResults} from "@azimutt/database-types"
import {Conn, QueryResultRow} from "./connect"

export const execQuery = (query: string, parameters: any[], name?: string) => (conn: Conn): Promise<DatabaseQueryResults> => {
    return conn.query(query, parameters, name).then(res => buildResults(query, res))
}

function buildResults(query: string, results: QueryResultRow[]): DatabaseQueryResults {
    const columns = Object.keys(results[0])
    return {
        query,
        columns: columns.map(name => ({name})), // TODO: parse SQL to infer column ref
        rows: results.map(row => columns.reduce((acc, col) => ({...acc, [col]: row[col]}), {}))
    }
}
