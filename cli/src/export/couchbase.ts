import chalk from "chalk";
import {Cluster, Collection, connect as open, PlanningFailureError} from "couchbase";
import {sequence} from "@azimutt/utils";
import {AzimuttSchema, DatabaseUrlParsed} from "@azimutt/database-types";
import {errorToString} from "../utils/error";
import {log, warn} from "../utils/logger";
import {schemaFromValues, schemaToColumns, ValueSchema} from "./infer";

export type CouchbaseSchema = { collections: CouchbaseCollection[] }
export type CouchbaseCollection = { bucket: CouchbaseBucketName, scope: CouchbaseScopeName, collection: CouchbaseCollectionName, schema: ValueSchema, sampleDocs: number, totalDocs: number }
export type CouchbaseBucketName = string
export type CouchbaseScopeName = string
export type CouchbaseCollectionName = string

export async function fetchSchema(url: DatabaseUrlParsed, bucketName: CouchbaseBucketName | undefined, sampleSize: number): Promise<CouchbaseSchema> {
    return connect(url, async cluster => {
        log('Connected to cluster ...')
        const bucketNames: CouchbaseBucketName[] = bucketName ? [bucketName] : await listBuckets(cluster)
        log(bucketName ? `Export for '${bucketName}' bucket ...` : `Found ${bucketNames.length} buckets to export ...`)

        const schemas = (await sequence(bucketNames, async b => {
            const bucket = cluster.bucket(b)
            const scopes = await bucket.collections().getAllScopes()
            return (await sequence(scopes, async s => {
                const scope = bucket.scope(s.name)
                const collections = s.collections.map(c => scope.collection(c.name))
                return await sequence(collections, c => infer(c, sampleSize))
            })).flat()
        })).flat()

        log('✔︎ All collections exported!')
        return {collections: schemas}
    })
}

export function transformSchema(schema: CouchbaseSchema, flatten: number, inferRelations: boolean): AzimuttSchema {
    // FIXME: handle inferRelations
    const tables = schema.collections.map(c => ({
        schema: c.bucket,
        table: `${c.scope}__${c.collection}`,
        columns: schemaToColumns(c.schema, flatten)
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

async function infer(collection: Collection, sampleSize: number): Promise<CouchbaseCollection> {
    // FIXME: fetch index informations & more
    const scope = collection.scope
    log(`Exporting collection ${collectionRef(collection)} ...`)
    const documents = await getSampleDocuments(collection, sampleSize)
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

async function getSampleDocuments(collection: Collection, sampleSize: number): Promise<any[]> {
    try {
        return (await collection.scope.query(`SELECT ${collection.name}.*
                                              FROM ${collection.name}
                                              LIMIT ${sampleSize}`)).rows
    } catch (e) {
        let err
        if (e instanceof PlanningFailureError) {
            err = (e.cause as any).first_error_message
        } else {
            err = errorToString(e)
        }
        warn(chalk.red(`Can't get sample documents for ${collectionRef(collection)}: ${err}`))
        return []
    }
}

function collectionRef(collection: Collection): string {
    return `${collection.scope.bucket.name}.${collection.scope.name}.${collection.name}`
}
