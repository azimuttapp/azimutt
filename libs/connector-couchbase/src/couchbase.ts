import {
    Cluster,
    Collection,
    PlanningFailureError,
    QueryResult,
    UnambiguousTimeoutError
} from "couchbase";
import {errorToString, Logger, sequence} from "@azimutt/utils";
import {AzimuttSchema, DatabaseUrlParsed} from "@azimutt/database-types";
import {schemaToColumns, ValueSchema, valuesToSchema} from "@azimutt/json-infer-schema";
import {connect} from "./connect";

export function execQuery(application: string, url: DatabaseUrlParsed, query: string, parameters: any[]): Promise<QueryResult> {
    return connect(application, url, cluster => cluster.query(query, {parameters}))
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

export async function getSchema(application: string, url: DatabaseUrlParsed, bucketName: CouchbaseBucketName | undefined, mixedCollection: string | undefined, sampleSize: number, ignoreErrors: boolean, logger: Logger): Promise<CouchbaseSchema> {
    return connect(application, url, async cluster => {
        logger.log('Connected to cluster ...')
        const bucketNames: CouchbaseBucketName[] = bucketName ? [bucketName] : await listBuckets(cluster, ignoreErrors, logger)
        logger.log(bucketName ? `Export for '${bucketName}' bucket ...` : `Found ${bucketNames.length} buckets to export ...`)

        const schemas = (await sequence(bucketNames, async b => {
            const bucket = cluster.bucket(b)
            const scopes = await bucket.collections().getAllScopes()
            return (await sequence(scopes, async s => {
                const scope = bucket.scope(s.name)
                const collections = s.collections.map(c => scope.collection(c.name))
                return (await sequence(collections, c => inferCollection(c, mixedCollection, sampleSize, ignoreErrors, logger))).flat()
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
        table: c.type && c.type.value ? `${c.collection}__${c.type.field}__${c.type.value}` : c.collection,
        columns: schemaToColumns(c.schema, 0)
    }))
    return {tables, relations: []}
}

// 👇️ Private functions, some are exported only for tests
// If you use them, beware of breaking changes!

async function listBuckets(cluster: Cluster, ignoreErrors: boolean, logger: Logger): Promise<CouchbaseBucketName[]> {
    return cluster.buckets().getAllBuckets()
        .then(buckets => buckets.map(b => b.name))
        .catch(handleError(`Failed to get buckets`, [], ignoreErrors, logger))
}

async function inferCollection(collection: Collection, mixedCollection: string | undefined, sampleSize: number, ignoreErrors: boolean, logger: Logger): Promise<CouchbaseCollection[]> {
    // FIXME: fetch index informations & more
    logger.log(`Exporting collection ${collectionRef(collection)} ...`)
    const types = mixedCollection ? await getCollectionTypes(collection, mixedCollection, ignoreErrors, logger) : [undefined]
    return sequence(types, type => inferCollectionForType(collection, type, sampleSize, ignoreErrors, logger))
}

async function getCollectionTypes(collection: Collection, mixedCollection: string, ignoreErrors: boolean, logger: Logger): Promise<CouchbaseCollectionType[]> {
    return query<{type: string}>(collection, `SELECT distinct ${mixedCollection} as type FROM ${collection.name}`)
        .then(rows => rows.map(r => ({field: mixedCollection, value: r.type})))
        .catch(handleError(`Failed to get types for '${collectionRef(collection)}'`, [], ignoreErrors, logger))
}

async function inferCollectionForType(collection: Collection, type: CouchbaseCollectionType | undefined, sampleSize: number, ignoreErrors: boolean, logger: Logger): Promise<CouchbaseCollection> {
    type && type.value && logger.log(`Exporting collection ${collectionRef(collection)} with ${type.field}=${type.value} ...`)
    const documents = await getSampleDocuments(collection, type, sampleSize, ignoreErrors, logger)
    const count = await countDocuments(collection, type, ignoreErrors, logger)
    return {
        bucket: collection.scope.bucket.name,
        scope: collection.scope.name,
        collection: collection.name,
        type,
        schema: valuesToSchema(documents),
        sampleDocs: documents.length,
        totalDocs: count
    }
}

async function getSampleDocuments(collection: Collection, type: CouchbaseCollectionType | undefined, sampleSize: number, ignoreErrors: boolean, logger: Logger): Promise<any[]> {
    return query(collection, `SELECT Meta() as _meta, ${collection.name}.* FROM ${collection.name}${filter(type)} LIMIT ${sampleSize}`)
        .catch(handleError(`Failed to get sample documents for '${collectionRef(collection)}'`, [], ignoreErrors, logger))
}

async function countDocuments(collection: Collection, type: CouchbaseCollectionType | undefined, ignoreErrors: boolean, logger: Logger): Promise<number> {
    return query<{count: number}>(collection, `SELECT count(*) as count FROM ${collection.name}${filter(type)}`)
        .then(rows => rows[0].count)
        .catch(handleError(`Failed to count documents for '${collectionRef(collection)}'`, 0, ignoreErrors, logger))
}

async function query<T = any>(collection: Collection, q: string): Promise<T[]> {
    const res = await collection.scope.query<T>(q)
    return res.rows
}

function filter(type: CouchbaseCollectionType | undefined): string {
    return type && type.value ? ` WHERE ${type.field}='${type.value}'` : ''
}

function collectionRef(collection: Collection): string {
    return `${collection.scope.bucket.name}.${collection.scope.name}.${collection.name}`
}

function handleError<T>(msg: string, value: T, ignoreErrors: boolean, logger: Logger) {
    return (err: any): Promise<T> => {
        if (ignoreErrors) {
            logger.warn(`${msg}: ${formatError(err)}. Ignoring...`)
            return Promise.resolve(value)
        } else {
            return Promise.reject(err)
        }
    }
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
