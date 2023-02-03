import {Collection, Document, MongoClient, WithId} from "mongodb";
import {sequence} from "../utils/promise";
import {AzimuttSchema} from "../utils/database";
import {log} from "../utils/logger";

export type MongoUrl = string
export type MongoSchema = { collections: MongoCollection[] }
export type MongoCollection = { db: MongoDatabaseName, name: MongoCollectionName, schema: MongoDocument, sampleDocs: number, totalDocs: number }
export type MongoDocument = { [key: string]: MongoDocumentValue }
export type MongoDocumentValue = { types: string[], nullable: boolean, values: any[] }
export type MongoDatabaseName = string
export type MongoCollectionName = string

export async function exportSchema(url: MongoUrl, databaseName: MongoDatabaseName | undefined, sampleSize: number): Promise<MongoSchema> {
    return await connect(url, async client => {
        log('Connected to database...')
        const databaseNames: MongoDatabaseName[] = databaseName ? [databaseName] : await listDatabases(client)
        log(databaseName ? `Export for '${databaseName}' database...` : `Found ${databaseNames.length} databases to export...`)
        const collections: Collection[] = (await sequence(databaseNames, dbName => client.db(dbName).collections())).flat()
        log(`Found ${collections.length} collections to export...`)
        const schemas: MongoCollection[] = await sequence(collections, collection => infer(collection, sampleSize))
        log('✔︎ All collections exported!')
        return {collections: schemas}
    })
}

export function transformSchema(schema: MongoSchema, flatten: boolean, inferRelations: boolean): AzimuttSchema {
    // FIXME: handle flatten
    // FIXME: handle inferRelations
    return {
        tables: schema.collections.map(c => ({
            schema: c.db,
            table: c.name,
            columns: Object.entries(c.schema).map(([key, value]) => ({
                name: key,
                type: value.types.join('|'),
                nullable: value.nullable
            }))
        })),
        relations: []
    }
}

async function listDatabases(client: MongoClient): Promise<MongoDatabaseName[]> {
    const adminDb = client.db('admin')
    const dbs = await adminDb.admin().listDatabases()
    return dbs.databases.map(db => db.name).filter(name => name !== 'local')
}

export async function connect<T>(url: MongoUrl, run: (c: MongoClient) => Promise<T>): Promise<T> {
    const client: MongoClient = new MongoClient(url)
    try {
        await client.connect()
        return await run(client)
    } catch (e) {
        return Promise.reject(e)
    } finally {
        await client.close() // Ensures that the client will close when you finish/error
    }
}

export async function infer(collection: Collection, sampleSize: number): Promise<MongoCollection> {
    // FIXME: fetch index informations
    // console.log('options', await collection.options()) // empty
    // console.log('indexes', await collection.indexes())
    // console.log('listIndexes', await collection.listIndexes().toArray()) // same result as indexes()
    // console.log('indexInformation', await collection.indexInformation()) // not much
    // console.log('stats', await collection.stats()) // several info
    log(`Exporting collection ${collection.dbName}.${collection.collectionName}...`)
    const documents: WithId<Document>[] = await collection.find({}, {limit: sampleSize}).toArray()
    return {
        db: collection.dbName,
        name: collection.collectionName,
        schema: documents.reduce(addToSchema, {}),
        sampleDocs: documents.length,
        totalDocs: await collection.estimatedDocumentCount()
    }
}

function addToSchema(schema: MongoDocument, doc: Document): MongoDocument {
    // FIXME: make inference recursive
    return Object.entries(doc).reduce((s, [key, value]) => {
        return {...s, [key]: s[key] ? enrichSchema(s[key], value) : initSchema(value)}
    }, schema)
}

function initSchema(value: any): MongoDocumentValue {
    return {types: [getType(value)], nullable: isNullable(value), values: [value]}
}

function enrichSchema(schema: MongoDocumentValue, value: any): MongoDocumentValue {
    const type = getType(value)
    return {
        types: schema.types.indexOf(type) !== -1 ? schema.types : schema.types.concat([type]),
        nullable: schema.nullable || isNullable(value),
        values: schema.values.concat([value])
    }
}

function getType(value: any): string {
    if (value === undefined) {
        return 'undefined'
    } else if (value === null) {
        return 'null'
    } else if (Array.isArray(value)) {
        return value.length > 0 ? getType(value[0]) + '[]' : '[]'
    } else if (typeof value === 'object') {
        return value.constructor.name
    } else {
        return typeof value
    }
}

function isNullable(value: any): boolean {
    return value === null || value === undefined
}
