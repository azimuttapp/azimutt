import {
    Cluster,
    Collection,
    connect as connectCB,
    PlanningFailureError,
    QueryResult,
    UnambiguousTimeoutError
} from "couchbase";
import {errorToString, Logger, sequence} from "@azimutt/utils";
import {AzimuttSchema, DatabaseUrlParsed} from "@azimutt/database-types";
import {schemaToColumns, ValueSchema, valuesToSchema} from "@azimutt/json-infer-schema";

export function execQuery(application: string, url: DatabaseUrlParsed, query: string, parameters: any[]): Promise<QueryResult> {
    return connect(url, cluster => cluster.query(query, {parameters}))
}

export type CouchbaseSchema = { collections: CouchbaseCollection[] }
export type CouchbaseCollection = {
    bucket: CouchbaseBucketName,
    scope: CouchbaseScopeName,
    collection: CouchbaseCollectionName,
    type?: CouchbaseCollectionType,
    schema: ValueSchema,
    sampleDocs: number,
    totalDocs: number
}
export type CouchbaseBucketName = string
export type CouchbaseScopeName = string
export type CouchbaseCollectionName = string
export type CouchbaseCollectionType = {field: string, value: string | undefined}

export async function getSchema(application: string, url: DatabaseUrlParsed, bucketName: CouchbaseBucketName | undefined, mixedCollection: string | undefined, sampleSize: number, logger: Logger): Promise<CouchbaseSchema> {
    return connect(url, async cluster => {
        logger.log('Connected to cluster ...')
        const bucketNames: CouchbaseBucketName[] = bucketName ? [bucketName] : await listBuckets(cluster)
        logger.log(bucketName ? `Export for '${bucketName}' bucket ...` : `Found ${bucketNames.length} buckets to export ...`)

        const schemas = (await sequence(bucketNames, async b => {
            const bucket = cluster.bucket(b)
            const scopes = await bucket.collections().getAllScopes()
            return (await sequence(scopes, async s => {
                const scope = bucket.scope(s.name)
                const collections = s.collections.map(c => scope.collection(c.name))
                return (await sequence(collections, c => inferCollection(c, mixedCollection, sampleSize, logger))).flat()
            })).flat()
        })).flat()

        logger.log('✔︎ All collections exported!')
        return {collections: schemas}
    })
}

export function formatSchema(schema: CouchbaseSchema, inferRelations: boolean): AzimuttSchema {
    // FIXME: handle inferRelations
    // /!\ we group `bucket` with `scope` as it's "similar" to the database level, grouping database & schema inside schema
    const tables = schema.collections.map(c => ({
        schema: `${c.bucket}__${c.scope}`,
        table: c.type && c.type.value ? `${c.collection}__${c.type.value}` : c.collection,
        columns: schemaToColumns(c.schema, 0)
    }))
    return {tables, relations: []}
}

// 👇️ Private functions, some are exported only for tests
// If you use them, beware of breaking changes!

async function listBuckets(cluster: Cluster): Promise<CouchbaseBucketName[]> {
    const buckets = await cluster.buckets().getAllBuckets()
    return buckets.map(b => b.name)
}

async function connect<T>(url: DatabaseUrlParsed, run: (c: Cluster) => Promise<T>): Promise<T> {
    const cluster: Cluster = await connectCB(url.full, {username: url.user, password: url.pass})
    try {
        return await run(cluster)
    } catch (e) {
        return Promise.reject(e)
    } finally {
        await cluster.close() // Ensures that the cluster will close when you finish/error
    }
}

async function inferCollection(collection: Collection, mixedCollection: string | undefined, sampleSize: number, logger: Logger): Promise<CouchbaseCollection[]> {
    // FIXME: fetch index informations & more
    logger.log(`Exporting collection ${collectionRef(collection)} ...`)
    const types = mixedCollection ? await getCollectionTypes(collection, mixedCollection, logger) : [undefined]
    return sequence(types, type => inferCollectionForType(collection, type, sampleSize, logger))
}

async function getCollectionTypes(collection: Collection, mixedCollection: string, logger: Logger): Promise<CouchbaseCollectionType[]> {
    try {
        const rows = await query<{type: string}>(collection, `SELECT distinct ${mixedCollection} as type FROM ${collection.name}`)
        return rows.map(r => ({field: mixedCollection, value: r.type}))
    } catch (e) {
        logger.error(`Can't get types for ${collectionRef(collection)}: ${formatError(e)}`)
        return []
    }
}

async function inferCollectionForType(collection: Collection, type: CouchbaseCollectionType | undefined, sampleSize: number, logger: Logger): Promise<CouchbaseCollection> {
    type && type.value && logger.log(`Exporting collection ${collectionRef(collection)} with ${type.field}=${type.value} ...`)
    const scope = collection.scope
    const documents = await getSampleDocuments(collection, type, sampleSize, logger)
    const count = await countDocuments(collection, type)
    return {
        bucket: scope.bucket.name,
        scope: scope.name,
        collection: collection.name,
        type,
        schema: valuesToSchema(documents),
        sampleDocs: documents.length,
        totalDocs: count
    }
}

async function countDocuments(collection: Collection, type: CouchbaseCollectionType | undefined): Promise<number> {
    const rows = await query<{count: number}>(collection, `SELECT count(*) as count FROM ${collection.name}${whereFragment(type)}`)
    return rows[0].count
}

async function getSampleDocuments(collection: Collection, type: CouchbaseCollectionType | undefined, sampleSize: number, logger: Logger): Promise<any[]> {
    try {
        return await query(collection, `SELECT Meta() as _meta, ${collection.name}.* FROM ${collection.name}${whereFragment(type)} LIMIT ${sampleSize}`)
    } catch (e) {
        logger.error(`Can't get sample documents for ${collectionRef(collection)}: ${formatError(e)}`)
        return []
    }
}

async function query<T = any>(collection: Collection, q: string): Promise<T[]> {
    const res = await collection.scope.query<T>(q)
    return res.rows
}

function whereFragment(type: CouchbaseCollectionType | undefined): string {
    return type && type.value ? ` WHERE ${type.field}='${type.value}'` : ''
}

function formatError(e: any): string {
    let err
    if (e instanceof PlanningFailureError) {
        err = (e.cause as any).first_error_message
    } else if (e instanceof UnambiguousTimeoutError) {
        err = e.message + '.\nMake sure you have access to the database, like no ip restriction or needed VPN.'
    } else {
        err = errorToString(e)
    }
    return err

}

function collectionRef(collection: Collection): string {
    return `${collection.scope.bucket.name}.${collection.scope.name}.${collection.name}`
}
