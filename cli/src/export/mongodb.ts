import {Collection, MongoClient} from "mongodb";
import {sequence} from "@azimutt/utils";
import {AzimuttSchema, DatabaseUrlParsed} from "@azimutt/database-types";
import {log} from "../utils/logger";
import {schemaFromValues, schemaToColumns, ValueSchema} from "./infer";

export type MongoSchema = { collections: MongoCollection[] }
export type MongoCollection = { db: MongoDatabaseName, name: MongoCollectionName, schema: ValueSchema, sampleDocs: number, totalDocs: number }
export type MongoDatabaseName = string
export type MongoCollectionName = string

export async function fetchSchema(url: DatabaseUrlParsed, databaseName: MongoDatabaseName | undefined, sampleSize: number): Promise<MongoSchema> {
    return await connect(url, async client => {
        log('Connected to database ...')
        const databaseNames: MongoDatabaseName[] = databaseName ? [databaseName] : await listDatabases(client)
        log(databaseName ? `Export for '${databaseName}' database ...` : `Found ${databaseNames.length} databases to export ...`)
        const collections: Collection[] = (await sequence(databaseNames, dbName => client.db(dbName).collections())).flat()
        log(`Found ${collections.length} collections to export ...`)
        const schemas: MongoCollection[] = await sequence(collections, collection => infer(collection, sampleSize))
        log('✔︎ All collections exported!')
        return {collections: schemas}
    })
}

export function transformSchema(schema: MongoSchema, flatten: number, inferRelations: boolean): AzimuttSchema {
    // FIXME: handle inferRelations
    const tables = schema.collections.map(c => ({
        schema: c.db,
        table: c.name,
        columns: schemaToColumns(c.schema, flatten)
    }))
    return {tables, relations: []}
}

async function listDatabases(client: MongoClient): Promise<MongoDatabaseName[]> {
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

async function infer(collection: Collection, sampleSize: number): Promise<MongoCollection> {
    // FIXME: fetch index informations & more
    // console.log('options', await collection.options()) // empty
    // console.log('indexes', await collection.indexes())
    // console.log('listIndexes', await collection.listIndexes().toArray()) // same result as indexes()
    // console.log('indexInformation', await collection.indexInformation()) // not much
    // console.log('stats', await collection.stats()) // several info
    log(`Exporting collection ${collection.dbName}.${collection.collectionName} ...`)
    const documents = await collection.find({}, {limit: sampleSize}).toArray()
    return {
        db: collection.dbName,
        name: collection.collectionName,
        schema: schemaFromValues(documents),
        sampleDocs: documents.length,
        totalDocs: await collection.estimatedDocumentCount()
    }
}
