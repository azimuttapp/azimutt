import mssql from "mssql";
import {AttributeValue, buildQueryAttributes, QueryResults} from "@azimutt/models";
import {ColumnMetadata, Conn, QueryResultArrayMode} from "./connect";

export const execQuery = (query: string, parameters: any[]) => (conn: Conn): Promise<QueryResults> => {
    return conn.queryArrayMode(query, parameters).then(result => buildResults(query, result))
}

function buildResults(query: string, result: QueryResultArrayMode): QueryResults {
    const attributes = buildQueryAttributes(result.fields, query)
    return QueryResults.parse({
        query,
        attributes,
        rows: result.rows.map(row => attributes.reduce((acc, col, i) => ({
            ...acc,
            [col.name]: buildValue(row[i], result.fields[i])
        }), {}))
    })
}

function buildValue(value: AttributeValue, field: ColumnMetadata | undefined): AttributeValue {
    if (typeof value === 'string' && (value.startsWith('[') || value.startsWith('{')) && field?.type === mssql.NVarChar) {
        // Can't get database or driver return JSON when needed
        // cf https://learn.microsoft.com/sql/relational-databases/json/format-query-results-as-json-with-for-json-sql-server
        // cf https://github.com/tediousjs/node-mssql#json-support
        // so do it manually 👇️
        try {
            return JSON.parse(value)
        } catch {
            return value
        }
    }
    if (typeof value === 'string' && field?.type === mssql.BigInt) {
        // `mssql.map.register(Number, mssql.BigInt)` didn't work :/
        // https://github.com/tediousjs/node-mssql#input-name-type-value
        // so do it manually 👇️
        return parseInt(value)
    }
    return value
}
