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
    const entityRef = getWildcardSelectTable(statement)
    return fields.map((f, i) => {
        const name = uniqueName(f.name, keys)
        keys[name] = true
        const ref = entityRef ? {...entityRef, attribute: [f.name]} : undefined
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

function uniqueName(name: string, currentNames: { [key: string]: true }, cpt: number = 1): string {
    const newName = cpt === 1 ? name : `${name}_${cpt}`
    if (currentNames[newName]) {
        return uniqueName(name, currentNames, cpt + 1)
    } else {
        return newName
    }
}
