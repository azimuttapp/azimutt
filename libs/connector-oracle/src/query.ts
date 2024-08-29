import * as oracledb from "oracledb";
import {AttributeValue, buildQueryAttributes, QueryResults} from "@azimutt/models";
import {Conn, QueryResultArrayMode} from "./connect";

export const execQuery = (query: string, parameters: any[]) => (conn: Conn): Promise<QueryResults> => {
    return conn.queryArrayMode(query, parameters).then(result => buildResults(conn, query, result))
}

async function buildResults(conn: Conn, query: string, result: QueryResultArrayMode): Promise<QueryResults> {
    const attributes = buildQueryAttributes(result.fields, query)
    const rows = await Promise.all(result.rows.map(async row => Object.fromEntries(await Promise.all(attributes.map((attr, i) => buildValue(row[i]).then(v => [attr.name, v]))))))
    return {query, attributes, rows}
}

async function buildValue(v: AttributeValue): Promise<AttributeValue> {
    if (typeof v === 'object' && v !== null && v.constructor.name === 'Lob') return getLobData(v as oracledb.Lob)
    return v
}

function getLobData(lob: oracledb.Lob): AttributeValue {
    return lob.getData().then(data => typeof data === 'string' ? data : data.toString())
}
