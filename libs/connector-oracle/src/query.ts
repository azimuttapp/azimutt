import {removeUndefined} from "@azimutt/utils";
import {AttributeRef, EntityRef, ParsedSqlStatement, parseSqlStatement, QueryResults} from "@azimutt/models";
import {Conn, QueryResultArrayMode, QueryResultField} from "./connect";

export const execQuery = (query: string, parameters: any[]) => (conn: Conn): Promise<QueryResults> => {
    return conn.queryArrayMode(query, parameters).then(result => buildResults(conn, query, result))
}

async function buildResults(conn: Conn, query: string, result: QueryResultArrayMode): Promise<QueryResults> {
    const attributes = buildAttributes(result.fields, parseSqlStatement(query))
    const rows = result.rows.map(row => attributes.reduce((acc, col, i) => ({...acc, [col.name]: row[i]}), {}))
    return {query, attributes, rows}
}

function buildAttributes(fields: QueryResultField[], statement: ParsedSqlStatement | undefined): { name: string; ref?: AttributeRef }[] {
    const keys: { [key: string]: true } = {}
    const wildcardTable = getWildcardSelectTable(statement)
    const allDefinedColumns = getAllDefinedColumns(statement, fields.length)
    return fields.map((f, i) => {
        const name = uniqueName(f.name, keys)
        keys[name] = true
        const ref = wildcardTable ? {...wildcardTable, attribute: [f.name]} : allDefinedColumns ? allDefinedColumns[i] : undefined
        return removeUndefined({name, ref})
    })
}

function getWildcardSelectTable(statement: ParsedSqlStatement | undefined): EntityRef | undefined {
    if (statement && statement.command === 'SELECT') {
        if (statement.joins === undefined && statement.columns.length === 1 && statement.columns[0].name === '*') {
            return removeUndefined({schema: statement.table.schema, entity: statement.table.name})
        }
    }
    return undefined
}

function getAllDefinedColumns(statement: ParsedSqlStatement | undefined, colCount: number): (AttributeRef | undefined)[] {
    if (statement && statement.command === 'SELECT') {
        if (statement.columns.length === colCount && statement.columns.every(c => c.name !== '*')) {
            const mainEntity: EntityRef = removeUndefined({schema: statement.table.schema, entity: statement.table.name})
            const aliases: { [alias: string]: EntityRef } = (statement.joins || []).reduce((acc, j) => {
                return j.alias ? {...acc, [j.alias]: removeUndefined({schema: j.schema, entity: j.table})} : acc
            }, statement.table.alias ? {[statement.table.alias]: mainEntity} : {})
            return statement.columns.map(c => {
                return c.col ? {...c.scope ? aliases[c.scope] : mainEntity, attribute: c.col} : undefined
            })
        }
    }
    return []
}

function uniqueName(name: string, currentNames: { [key: string]: true }, cpt: number = 1): string {
    const newName = cpt === 1 ? name : `${name}_${cpt}`
    if (currentNames[newName]) {
        return uniqueName(name, currentNames, cpt + 1)
    } else {
        return newName
    }
}
