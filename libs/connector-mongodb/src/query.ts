import {distinct, removeUndefined} from "@azimutt/utils";
import {QueryResults} from "@azimutt/models";
import {Conn} from "./connect";
import {parseMongoStatement} from "./parser";

/*
    The `query` is a MongoDB query (like: 'db.users.find({"id": 1});').
    The parser should handle most of them, look at it and its [tests](./parser.test.ts) for some examples.

    Legacy query was in the form of: "$db/$collection/$operation/$command/$limit".
    Stop using it, it will be removed at some point.
 */
export const execQuery = (query: string, parameters: any[]) => async (conn: Conn): Promise<QueryResults> => {
    const statement = parseMongoStatement(query)
    if (typeof statement === 'string') return Promise.reject(`Invalid MongoDB query: ${statement}, query: ${query}`)
    const coll = conn.underlying.db(statement.database).collection(statement.collection) as any
    if (typeof coll[statement.operation] === 'function') {
        let mongoQuery = coll[statement.operation](statement.command)
        mongoQuery = statement.projection ? mongoQuery.project(statement.projection) : mongoQuery
        mongoQuery = statement.limit ? mongoQuery.limit(statement.limit) : mongoQuery
        const rows: any[] = await mongoQuery.toArray()
        const allKeys: string[] = rows.flatMap(Object.keys)
        return QueryResults.parse({
            query,
            attributes: distinct(allKeys).map(name => ({
                name,
                ref: removeUndefined({
                    schema: statement.database,
                    entity: statement.collection,
                    attribute: [name]
                })
            })),
            rows: rows.map(row => JSON.parse(JSON.stringify(row))) // serialize ObjectId & Date objects
        })
    } else {
        return Promise.reject(`Invalid MongoDB operation (${statement.operation})`)
    }
}
