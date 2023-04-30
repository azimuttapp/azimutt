import {Collection, MongoClient} from "mongodb";
import {Logger, sequence} from "@azimutt/utils";
import {AzimuttSchema, DatabaseResults, DatabaseUrlParsed} from "@azimutt/database-types";
import {schemaFromValues, schemaToColumns, ValueSchema} from "@azimutt/json-infer-schema";

// expects `query` to be in the form of: "db/collection/operation/command"
// - `db`: name of the database to use
// - `collection`: name of the collection to use
// - `operation`: name of the collection method to call (see https://mongodb.github.io/node-mongodb-native/5.3/classes/Collection.html)
// - `command`: the JSON given as parameter for the operation
export function execQuery(application: string, url: DatabaseUrlParsed, query: string): Promise<DatabaseResults> {
    return connect(url, async client => {
        // Ugly hack to have a single string query perform any operation on MongoDB 🤮
        // If you see this and have an idea how to improve, please reach out (issue, PR, twitter, email, slack... ^^)
        const [db, collection, operation, commandStr] = query.split('/').map(v => v.trim())
        let command
        try {
            command = JSON.parse(commandStr)
        } catch (e) {
            return Promise.reject(`'${commandStr}' is not a valid JSON (expected for the command)`)
        }
        const coll = client.db(db).collection(collection) as any
        if (typeof coll[operation] === 'function') {
            const rows = await coll[operation](command).toArray()
            return {db, collection, operation, command, rows}
        } else {
            return Promise.reject(`'${operation}' is not a valid MongoDB operation`)
        }
    })
}

export type MongodbSchema = { collections: MongodbCollection[] }
export type MongodbCollection = { database: MongodbDatabaseName, collection: MongodbCollectionName, schema: ValueSchema, sampleDocs: number, totalDocs: number }
export type MongodbDatabaseName = string
export type MongodbCollectionName = string

export async function getSchema(application: string, url: DatabaseUrlParsed, databaseName: MongodbDatabaseName | undefined, sampleSize: number, logger: Logger): Promise<MongodbSchema> {
    return connect(url, async client => {
        logger.log('Connected to database ...')
        const databaseNames: MongodbDatabaseName[] = databaseName ? [databaseName] : await listDatabases(client)
        logger.log(databaseName ? `Export for '${databaseName}' database ...` : `Found ${databaseNames.length} databases to export ...`)
        const collections: Collection[] = (await sequence(databaseNames, dbName => client.db(dbName).collections())).flat()
        logger.log(`Found ${collections.length} collections to export ...`)
        const schemas: MongodbCollection[] = await sequence(collections, collection => infer(collection, sampleSize, logger))
        logger.log('✔︎ All collections exported!')
        return {collections: schemas}
    })
}

export function formatSchema(schema: MongodbSchema, inferRelations: boolean): AzimuttSchema {
    // FIXME: handle inferRelations
    const tables = schema.collections.map(c => ({
        schema: c.database,
        table: c.collection,
        columns: schemaToColumns(c.schema, 0)
    }))
    return {tables, relations: []}
}

async function listDatabases(client: MongoClient): Promise<MongodbDatabaseName[]> {
    const adminDb = client.db('admin')
    const dbs = await adminDb.admin().listDatabases()
    return dbs.databases.map(db => db.name).filter(name => name !== 'local')
}

async function connect<T>(url: DatabaseUrlParsed, run: (c: MongoClient) => Promise<T>): Promise<T> {
    const client: MongoClient = new MongoClient(url.full)
    try {
        await client.connect()
        return await run(client)
    } catch (e) {
        return Promise.reject(e)
    } finally {
        await client.close() // Ensures that the client will close when you finish/error
    }
}

async function infer(collection: Collection, sampleSize: number, logger: Logger): Promise<MongodbCollection> {
    // FIXME: fetch index informations & more
    // console.log('options', await collection.options()) // empty
    // console.log('indexes', await collection.indexes())
    // console.log('listIndexes', await collection.listIndexes().toArray()) // same result as indexes()
    // console.log('indexInformation', await collection.indexInformation()) // not much
    // console.log('stats', await collection.stats()) // several info
    logger.log(`Exporting collection ${collection.dbName}.${collection.collectionName} ...`)
    const documents = await collection.find({}, {limit: sampleSize}).toArray()
    return {
        database: collection.dbName,
        collection: collection.collectionName,
        schema: schemaFromValues(documents),
        sampleDocs: documents.length,
        totalDocs: await collection.estimatedDocumentCount()
    }
}
