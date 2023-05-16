import {Collection, Filter, MongoClient} from "mongodb";
import {Logger, sequence} from "@azimutt/utils";
import {AzimuttSchema, DatabaseUrlParsed} from "@azimutt/database-types";
import {schemaToColumns, ValueSchema, valuesToSchema} from "@azimutt/json-infer-schema";

export type QueryResult = { database: string, collection: string, operation: string, command: object, rows: object[] }

// expects `query` to be in the form of: "db/collection/operation/command"
// - `db`: name of the database to use
// - `collection`: name of the collection to use
// - `operation`: name of the collection method to call (see https://mongodb.github.io/node-mongodb-native/5.3/classes/Collection.html)
// - `command`: the JSON given as parameter for the operation
export function execQuery(application: string, url: DatabaseUrlParsed, query: string): Promise<QueryResult> {
    return connect(url, async client => {
        // Ugly hack to have a single string query perform any operation on MongoDB 🤮
        // If you see this and have an idea how to improve, please reach out (issue, PR, twitter, email, slack... ^^)
        const [database, collection, operation, commandStr, limit] = query.split('/').map(v => v.trim())
        let command
        try {
            command = JSON.parse(commandStr)
        } catch (e) {
            return Promise.reject(`'${commandStr}' is not a valid JSON (expected for the command)`)
        }
        const coll = client.db(database).collection(collection) as any
        if (typeof coll[operation] === 'function') {
            const rows = await limitResults(coll[operation](command), limit).toArray()
            return {database, collection, operation, command, rows}
        } else {
            return Promise.reject(`'${operation}' is not a valid MongoDB operation`)
        }
    })
}

function limitResults(query: any, limit: string) {
    const l = parseInt(limit)
    return l ? query.limit(l) : query
}

export type MongodbSchema = { collections: MongodbCollection[] }
export type MongodbCollection = {
    database: MongodbDatabaseName,
    collection: MongodbCollectionName,
    type?: MongodbCollectionType,
    schema: ValueSchema,
    sampleDocs: number,
    totalDocs: number
}
export type MongodbDatabaseName = string
export type MongodbCollectionName = string
export type MongodbCollectionType = {field: string, value: string | undefined}

export async function getSchema(application: string, url: DatabaseUrlParsed, databaseName: MongodbDatabaseName | undefined, mixedCollection: string | undefined, sampleSize: number, logger: Logger): Promise<MongodbSchema> {
    return connect(url, async client => {
        logger.log('Connected to database ...')
        const databaseNames: MongodbDatabaseName[] = databaseName ? [databaseName] : await listDatabases(client)
        logger.log(databaseName ? `Export for '${databaseName}' database ...` : `Found ${databaseNames.length} databases to export ...`)
        const collections: Collection[] = (await sequence(databaseNames, dbName => client.db(dbName).collections())).flat()
        logger.log(`Found ${collections.length} collections to export ...`)
        const schemas: MongodbCollection[] = (await sequence(collections, collection => inferCollection(collection, mixedCollection, sampleSize, logger))).flat()
        logger.log('✔︎ All collections exported!')
        return {collections: schemas}
    })
}

export function formatSchema(schema: MongodbSchema, inferRelations: boolean): AzimuttSchema {
    // FIXME: handle inferRelations
    const tables = schema.collections.map(c => ({
        schema: c.database,
        table: c.type && c.type.value ? `${c.collection}__${c.type.field}__${c.type.value}` : c.collection,
        columns: schemaToColumns(c.schema, 0)
    }))
    return {tables, relations: []}
}

// 👇️ Private functions, some are exported only for tests
// If you use them, beware of breaking changes!

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

async function inferCollection(collection: Collection, mixedCollection: string | undefined, sampleSize: number, logger: Logger): Promise<MongodbCollection[]> {
    // FIXME: fetch index informations & more
    // console.log('options', await collection.options()) // empty
    // console.log('indexes', await collection.indexes())
    // console.log('listIndexes', await collection.listIndexes().toArray()) // same result as indexes()
    // console.log('indexInformation', await collection.indexInformation()) // not much
    // console.log('stats', await collection.stats()) // several info
    logger.log(`Exporting collection ${collectionRef(collection)} ...`)
    const types = mixedCollection ? await getCollectionTypes(collection, mixedCollection) : [undefined]
    return sequence(types, type => inferCollectionForType(collection, type, sampleSize, logger))
}

async function getCollectionTypes(collection: Collection, mixedCollection: string): Promise<MongodbCollectionType[]> {
    const values = await collection.distinct(mixedCollection)
    return values.map(value => ({field: mixedCollection, value}))
}

async function inferCollectionForType(collection: Collection, type: MongodbCollectionType | undefined, sampleSize: number, logger: Logger): Promise<MongodbCollection> {
    type && type.value && logger.log(`Exporting collection ${collectionRef(collection)} with ${type.field}=${type.value} ...`)
    const documents = await getSampleDocuments(collection, type, sampleSize)
    const count = await countDocuments(collection, type)
    return {
        database: collection.dbName,
        collection: collection.collectionName,
        type,
        schema: valuesToSchema(documents),
        sampleDocs: documents.length,
        totalDocs: count
    }
}

async function getSampleDocuments(collection: Collection, type: MongodbCollectionType | undefined, sampleSize: number): Promise<any[]> {
    return await collection.find(filter(type)).limit(sampleSize).toArray()
}

async function countDocuments(collection: Collection, type: MongodbCollectionType | undefined): Promise<number> {
    return await collection.countDocuments(filter(type))
}

function filter(type: MongodbCollectionType | undefined): Filter<any> {
    return type && type.value ? {[type.field]: type.value} : {}
}

function collectionRef(collection: Collection): string {
    return `${collection.dbName}.${collection.collectionName}`
}
