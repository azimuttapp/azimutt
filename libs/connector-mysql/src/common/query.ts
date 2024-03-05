import {DatabaseQueryResults, DatabaseQueryResultsColumn} from "@azimutt/database-types";
import {Conn, QueryResultArrayMode, QueryResultField} from "./types";

export const execQuery = (query: string, parameters: any[]) => (conn: Conn): Promise<DatabaseQueryResults> => {
    return conn.queryArrayMode(query, parameters).then(result => buildResults(query, result))
}

function buildResults(query: string, result: QueryResultArrayMode): DatabaseQueryResults {
    const columns = buildColumns(result.fields)
    return {
        query,
        columns,
        rows: result.rows.map(row => columns.reduce((acc, col, i) => ({...acc, [col.name]: row[i]}), {}))
    }
}

function buildColumns(fields: QueryResultField[]): DatabaseQueryResultsColumn[] {
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
