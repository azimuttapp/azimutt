import {DatabaseQueryResults, DatabaseQueryResultsColumn, DatabaseUrlParsed} from "@azimutt/database-types";
import {connect} from "./connect";
import {FieldPacket, RowDataPacket} from "mysql2";

export function execQuery(application: string, url: DatabaseUrlParsed, query: string, parameters: any[]): Promise<DatabaseQueryResults> {
    return connect(application, url, conn => {
        return conn.query<RowDataPacket[][]>({sql: query, values: parameters, rowsAsArray: true}).then(([rows, fields]) => {
            return buildResults(query, fields, rows)
        })
    })
}

function buildResults(query: string, fields: FieldPacket[], rows: RowDataPacket[][]): DatabaseQueryResults {
    const columns = buildColumns(fields)
    return {
        query,
        columns,
        rows: rows.map(row => columns.reduce((acc, col, i) => ({...acc, [col.name]: row[i]}), {}))
    }
}

function buildColumns(fields: FieldPacket[]): DatabaseQueryResultsColumn[] {
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
