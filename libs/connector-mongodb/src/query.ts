import {QueryResults} from "@azimutt/database-model";
import {Conn} from "./connect";
import {distinct} from "@azimutt/utils";

// expects `query` to be in the form of: "db/collection/operation/command"
// - `db`: name of the database to use
// - `collection`: name of the collection to use
// - `operation`: name of the collection method to call (see https://mongodb.github.io/node-mongodb-native/5.3/classes/Collection.html)
// - `command`: the JSON given as parameter for the operation
export const execQuery = (query: string, parameters: any[]) => async (conn: Conn): Promise<QueryResults> => {
    // Ugly hack to have a single string query perform any operation on MongoDB 🤮
    // If you see this and have an idea how to improve, please reach out (issue, PR, twitter, email, slack... ^^)
    const [database, collection, operation, commandStr, limit] = query.split('/').map(v => v.trim())
    let command
    try {
        command = JSON.parse(commandStr)
    } catch (e) {
        return Promise.reject(`'${commandStr}' is not a valid JSON (expected for the command)`)
    }
    const coll = conn.underlying.db(database).collection(collection) as any
    if (typeof coll[operation] === 'function') {
        const rows: any[] = await limitResults(coll[operation](command), limit).toArray()
        const allKeys: string[] = rows.flatMap(Object.keys)
        return QueryResults.parse({
            query,
            attributes: distinct(allKeys).map(name => ({name})),
            rows: rows.map(row => JSON.parse(JSON.stringify(row))) // serialize ObjectId & Date objects
        })
    } else {
        return Promise.reject(`'${operation}' is not a valid MongoDB operation`)
    }

}

function limitResults(query: any, limit: string | undefined) {
    const l = limit ? (parseInt(limit) || 100) : 100
    return query.limit(l)
}
