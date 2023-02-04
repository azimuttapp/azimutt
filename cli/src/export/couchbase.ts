import {Bucket, Cluster, Collection, connect as open, Scope} from "couchbase";
import {schemaFromValues, schemaToColumns, ValueSchema} from "./infer";
import {AzimuttSchema, DbUrl} from "../utils/database";
import {sequence} from "../utils/promise";
import {log} from "../utils/logger";

export type CouchbaseSchema = { collections: CouchbaseCollection[] }
export type CouchbaseCollection = { bucket: CouchbaseBucketName, scope: CouchbaseScopeName, collection: CouchbaseCollectionName, schema: ValueSchema, sampleDocs: number, totalDocs: number }
export type CouchbaseBucketName = string
export type CouchbaseScopeName = string
export type CouchbaseCollectionName = string
type ScopeFull = { scope: Scope, collections: CouchbaseCollectionName[] }

export async function exportSchema(url: DbUrl, bucketName: CouchbaseBucketName | undefined, sampleSize: number): Promise<CouchbaseSchema> {
    return connect(url, async cluster => {
        log('Connected to cluster...')
        const bucketNames: CouchbaseBucketName[] = bucketName ? [bucketName] : await listBuckets(cluster)
        log(bucketName ? `Export for '${bucketName}' bucket...` : `Found ${bucketNames.length} buckets to export...`)
        const buckets: Bucket[] = bucketNames.map(b => cluster.bucket(b))
        const scopes: ScopeFull[] = (await sequence(buckets, async b => (await b.collections().getAllScopes()).map(s => ({
            scope: b.scope(s.name),
            collections: s.collections.map(c => c.name)
        })))).flat()
        log(`Found ${scopes.length} scopes to export...`)
        const collections: Collection[] = scopes.flatMap(({scope, collections}) => collections.map(scope.collection))
        log(`Found ${collections.length} collections to export...`)
        const schemas = await sequence(collections, collection => infer(collection, sampleSize))
        log('✔︎ All collections exported!')
        return {collections: schemas}
    })
}

export function transformSchema(schema: CouchbaseSchema, flatten: number, inferRelations: boolean): AzimuttSchema {
    // FIXME: handle inferRelations
    const tables = schema.collections.map(c => ({
        schema: c.bucket,
        table: `${c.scope}/${c.collection}`,
        columns: schemaToColumns(c.schema, flatten)
    }))
    return {tables, relations: []}
}

async function listBuckets(cluster: Cluster): Promise<CouchbaseBucketName[]> {
    return (await cluster.buckets().getAllBuckets()).map(b => b.name)
}

async function connect<T>(url: DbUrl, run: (c: Cluster) => Promise<T>): Promise<T> {
    const cluster: Cluster = await open(url.full, {username: url.user, password: url.pass})
    try {
        return await run(cluster)
    } catch (e) {
        return Promise.reject(e)
    } finally {
        await cluster.close() // Ensures that the cluster will close when you finish/error
    }
}

async function infer(collection: Collection, sampleSize: number): Promise<CouchbaseCollection> {
    // FIXME: fetch index informations & more
    const scope = collection.scope
    log(`Exporting collection ${scope.bucket.name}.${scope.name}.${collection.name}...`)
    const documents = (await scope.query(`SELECT ${collection.name}.*
                                          FROM ${collection.name}
                                          LIMIT ${sampleSize}`)).rows
    const count = (await scope.query(`SELECT count(*) as count
                                      FROM ${collection.name}`)).rows[0].count
    return {
        bucket: scope.bucket.name,
        scope: scope.name,
        collection: collection.name,
        schema: schemaFromValues(documents),
        sampleDocs: documents.length,
        totalDocs: count
    }
}
