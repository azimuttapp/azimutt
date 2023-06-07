import {IResult} from "mssql";
import {DatabaseQueryResults, DatabaseQueryResultsColumn, DatabaseUrlParsed} from "@azimutt/database-types";
import {ColumnMetadata} from "./types";
import {connect} from "./connect";

export function execQuery(application: string, url: DatabaseUrlParsed, query: string, parameters: any[]): Promise<DatabaseQueryResults> {
    return connect(application, url, conn => {
        const request = conn.request() as any
        request.arrayRowMode = true
        return request.query(query, parameters).then((result: IResult<any> & {columns: ColumnMetadata[][]}) => {
            return buildResults(query, result.columns[0], result.recordset)
        })
    })
}

function buildResults(query: string, fields: ColumnMetadata[], rows: any[][]): DatabaseQueryResults {
    const columns = buildColumns(fields)
    return {
        query,
        columns,
        rows: rows.map(row => columns.reduce((acc, col, i) => ({...acc, [col.name]: row[i]}), {}))
    }
}

function buildColumns(fields: ColumnMetadata[]): DatabaseQueryResultsColumn[] {
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
