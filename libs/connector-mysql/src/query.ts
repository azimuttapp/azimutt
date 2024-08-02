import {buildQueryAttributes, QueryResults} from "@azimutt/models";
import {Conn, QueryResultArrayMode} from "./connect";

export const execQuery = (query: string, parameters: any[]) => (conn: Conn): Promise<QueryResults> => {
    return conn.queryArrayMode(query, parameters).then(result => buildResults(query, result))
}

function buildResults(query: string, result: QueryResultArrayMode): QueryResults {
    const attributes = buildQueryAttributes(result.fields.map(f => f.name), query)
    return QueryResults.parse({
        query,
        attributes,
        rows: result.rows.map(row => attributes.reduce((acc, col, i) => ({...acc, [col.name]: row[i]}), {}))
    })
}
