import {
    Cluster,
    Collection,
    connect as open,
    PlanningFailureError,
    QueryResult,
    UnambiguousTimeoutError
} from "couchbase";
import {errorToString, Logger, sequence} from "@azimutt/utils";
import {AzimuttSchema, DatabaseUrlParsed} from "@azimutt/database-types";
import {valuesToSchema, schemaToColumns, ValueSchema} from "@azimutt/json-infer-schema";


export function execQuery(application: string, url: DatabaseUrlParsed, query: string, parameters: any[]): Promise<QueryResult> {
    return connect(url, cluster => cluster.query(query, {parameters}))
}

export type CouchbaseSchema = { collections: CouchbaseCollection[] }
export type CouchbaseCollection = { bucket: CouchbaseBucketName, scope: CouchbaseScopeName, collection: CouchbaseCollectionName, schema: ValueSchema, sampleDocs: number, totalDocs: number }
export type CouchbaseBucketName = string
export type CouchbaseScopeName = string
export type CouchbaseCollectionName = string

export async function getSchema(application: string, url: DatabaseUrlParsed, bucketName: CouchbaseBucketName | undefined, sampleSize: number, logger: Logger): Promise<CouchbaseSchema> {
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
                return await sequence(collections, c => infer(c, sampleSize, logger))
            })).flat()
        })).flat()

        logger.log('✔︎ All collections exported!')
        return {collections: schemas}
    })
}

export function formatSchema(schema: CouchbaseSchema, inferRelations: boolean): AzimuttSchema {
    // FIXME: handle inferRelations
    // /!\ we choose to ignore the `bucket` as it's "similar" to the database level we don't handle in AzimuttSchema
    const tables = schema.collections.map(c => ({
        schema: c.scope,
        table: c.collection,
        columns: schemaToColumns(c.schema, 0)
    }))
    return {tables, relations: []}
}

async function listBuckets(cluster: Cluster): Promise<CouchbaseBucketName[]> {
    return (await cluster.buckets().getAllBuckets()).map(b => b.name)
}

async function connect<T>(url: DatabaseUrlParsed, run: (c: Cluster) => Promise<T>): Promise<T> {
    const cluster: Cluster = await open(url.full, {username: url.user, password: url.pass})
    try {
        return await run(cluster)
    } catch (e) {
        return Promise.reject(e)
    } finally {
        await cluster.close() // Ensures that the cluster will close when you finish/error
    }
}

async function infer(collection: Collection, sampleSize: number, logger: Logger): Promise<CouchbaseCollection> {
    // FIXME: fetch index informations & more
    const scope = collection.scope
    logger.log(`Exporting collection ${collectionRef(collection)} ...`)
    const documents = await getSampleDocuments(collection, sampleSize, logger)
    const count = (await scope.query(`SELECT count(*) as count
                                      FROM ${collection.name}`)).rows[0].count
    return {
        bucket: scope.bucket.name,
        scope: scope.name,
        collection: collection.name,
        schema: valuesToSchema(documents),
        sampleDocs: documents.length,
        totalDocs: count
    }
}

async function getSampleDocuments(collection: Collection, sampleSize: number, logger: Logger): Promise<any[]> {
    try {
        return (await collection.scope.query(`SELECT ${collection.name}.*
                                              FROM ${collection.name}
                                              LIMIT ${sampleSize}`)).rows
    } catch (e) {
        let err
        if (e instanceof PlanningFailureError) {
            err = (e.cause as any).first_error_message
        } else if (e instanceof UnambiguousTimeoutError) {
            err = e.message + '.\nMake sure you have access to the database, like no ip restriction or needed VPN.'
        } else {
            err = errorToString(e)
        }
        logger.error(`Can't get sample documents for ${collectionRef(collection)}: ${err}`)
        return []
    }
}

function collectionRef(collection: Collection): string {
    return `${collection.scope.bucket.name}.${collection.scope.name}.${collection.name}`
}
