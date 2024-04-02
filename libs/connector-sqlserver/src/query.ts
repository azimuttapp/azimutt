import {QueryResults, QueryResultsAttribute} from "@azimutt/database-model";
import {Conn, QueryResultArrayMode, QueryResultField} from "./connect";

export const execQuery = (query: string, parameters: any[]) => (conn: Conn): Promise<QueryResults> => {
    return conn.queryArrayMode(query, parameters).then(result => buildResults(query, result))
}

function buildResults(query: string, result: QueryResultArrayMode): QueryResults {
    const attributes = buildColumns(result.fields)
    return QueryResults.parse({
        query,
        attributes,
        rows: result.rows.map(row => attributes.reduce((acc, col, i) => ({...acc, [col.name]: row[i]}), {}))
    })
}

function buildColumns(fields: QueryResultField[]): QueryResultsAttribute[] {
    const keys: { [key: string]: true } = {}
    return fields.map(f => {
        const name = uniqueName(f.name, keys)
        keys[name] = true
        return {name}
    })
}

function uniqueName(name: string, currentNames: { [key: string]: true }, cpt: number = 1): string {
    const newName = cpt === 1 ? name : `${name}_${cpt}`
    if (currentNames[newName]) {
        return uniqueName(name, currentNames, cpt + 1)
    } else {
        return newName
    }
}
