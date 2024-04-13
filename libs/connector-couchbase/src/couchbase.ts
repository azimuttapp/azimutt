import {Bucket, Collection, ScopeSpec} from "couchbase";
import {joinLimit, pluralizeL, removeUndefined, sequence} from "@azimutt/utils";
import {
    AttributeName,
    AttributeValue,
    ConnectorSchemaOpts,
    connectorSchemaOptsDefaults,
    Database,
    Entity,
    formatConnectorScope,
    handleError,
    schemaToAttributes,
    valuesToSchema
} from "@azimutt/models";
import {scopeFilter} from "./helpers";
import {Conn} from "./connect";

export const getSchema = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<Database> => {
    const scope = formatConnectorScope({catalog: 'bucket', schema: 'scope', entity: 'collection'}, opts)
    opts.logger.log(`Connected to the cluster${scope ? `, exporting for ${scope}` : ''} ...`)
    const buckets: Bucket[] = await getBuckets(opts)(conn)
    opts.logger.log(`Found ${pluralizeL(buckets, 'bucket')} to export (${joinLimit(buckets.map(b => b.name))}) ...`)

    const entities: Entity[] = (await sequence(buckets, async bucket => {
        const scopes = await getScopes(bucket, opts)(conn)
        opts.logger.log(`  Found ${pluralizeL(scopes, 'scope')} to export in bucket '${bucket.name}' (${joinLimit(scopes.map(b => b.name))}) ...`)
        return (await sequence(scopes, async scope => {
            const collections = getCollections(bucket, scope, opts)(conn)
            opts.logger.log(`    Found ${pluralizeL(collections, 'collection')} to export in scope '${bucket.name}.${scope.name}' (${joinLimit(collections.map(b => b.name))}) ...`)
            return (await sequence(collections, collection => {
                opts.logger.log(`      Exporting collection ${collectionId(collection)} ...`)
                return inferCollection('      ', collection, opts)(conn)
            })).flat()
        })).flat()
    })).flat()

    opts.logger.log(`✔︎ Exported ${pluralizeL(entities, 'collection')} from the cluster!`)
    return removeUndefined({
        entities,
        relations: undefined,
        types: undefined,
        doc: undefined,
        stats: undefined,
        extra: undefined,
    })
}

// 👇️ Private functions, some are exported only for tests
// If you use them, beware of breaking changes!

const getBuckets = (opts: ConnectorSchemaOpts) => (conn: Conn): Promise<Bucket[]> => {
    if (opts.catalog && !opts.catalog.includes('%')) {
        return Promise.resolve([conn.underlying.bucket(opts.catalog)])
    } else {
        return conn.underlying.buckets().getAllBuckets().then(buckets =>
            buckets.map(b => conn.underlying.bucket(b.name)).filter(b => scopeFilter({catalog: b.name}, opts))
        ).catch(handleError(`Failed to get buckets`, [], opts))
    }
}

const getScopes = (bucket: Bucket, opts: ConnectorSchemaOpts) => (conn: Conn): Promise<ScopeSpec[]> => {
    return bucket.collections().getAllScopes()
        .then(cols => cols.filter(scope => scopeFilter({schema: scope.name}, opts)))
        .catch(handleError(`Failed to get scopes for bucket '${bucket.name}'`, [], opts))
}

const getCollections = (bucket: Bucket, s: ScopeSpec, opts: ConnectorSchemaOpts) => (conn: Conn): Collection[] => {
    const scope = bucket.scope(s.name)
    return s.collections.filter(c => scopeFilter({entity: c.name}, opts)).map(c => scope.collection(c.name))
}

// TODO: allow nested attribute
type MixedCollection = {attribute: AttributeName, value: string}

const inferCollection = (indent: string, collection: Collection, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<Entity[]> => {
    // FIXME: fetch index informations & more
    if (opts.inferMixedJson) {
        const attribute: AttributeName = opts.inferMixedJson
        const values = await getDistinctValues(collection, attribute, opts)
            .then(values => values.filter((v): v is string => typeof v === 'string'))
        if (values.length > 0) {
            opts.logger.log(`${indent}Found ${pluralizeL(values, 'kind')} to export (${joinLimit(values)}) ...`)
            return sequence(values, value => {
                opts.logger.log(`${indent}  Exporting collection ${collectionId(collection)} for ${attribute}=${value} ...`)
                return inferCollectionMixed(collection, {attribute, value}, opts)
            })
        } else {
            return [await inferCollectionMixed(collection, null, opts)]
        }
    } else {
        return [await inferCollectionMixed(collection, null, opts)]
    }
}

async function getDistinctValues(collection: Collection, attribute: AttributeName, opts: ConnectorSchemaOpts): Promise<AttributeValue[]> {
    return query<{value: AttributeValue}>(collection, `SELECT distinct ${attribute} AS value FROM ${collection.name};`)
        .then(rows => rows.map(row => row.value))
        .catch(handleError(`Failed to get distinct values for '${collectionId(collection)}(${attribute})'`, [], opts))
}

async function inferCollectionMixed(collection: Collection, mixed: MixedCollection | null, opts: ConnectorSchemaOpts): Promise<Entity> {
    const documents = await getSampleDocuments(collection, mixed, opts)
    const count = await countDocuments(collection, mixed, opts)
    return removeUndefined({
        catalog: collection.scope.bucket.name,
        schema: collection.scope.name,
        name: mixed ? `${collection.name}__${mixed.attribute}__${mixed.value}` : collection.name,
        kind: undefined,
        def: undefined,
        attrs: schemaToAttributes(valuesToSchema(documents), 0),
        pk: undefined,
        indexes: undefined,
        checks: undefined,
        doc: undefined,
        stats: removeUndefined({
            rows: count,
            size: undefined,
            sizeIdx: undefined,
            sizeToast: undefined,
            sizeToastIdx: undefined,
            seq_scan: undefined,
            idx_scan: undefined,
        }),
        extra: undefined
    })
}

type CollectionDoc = any

async function getSampleDocuments(collection: Collection, mixed: MixedCollection | null, opts: ConnectorSchemaOpts): Promise<CollectionDoc[]> {
    const sampleSize = opts.sampleSize || connectorSchemaOptsDefaults.sampleSize
    return query(collection, `SELECT Meta() AS _meta, ${collection.name}.* FROM ${collection.name}${buildFilter(mixed)} LIMIT ${sampleSize};`)
        .catch(handleError(`Failed to get sample documents for '${collectionId(collection)}${formatMixed(mixed)}'`, [], opts))
}

async function countDocuments(collection: Collection, mixed: MixedCollection | null, opts: ConnectorSchemaOpts): Promise<number> {
    return query<{count: number}>(collection, `SELECT count(*) AS count FROM ${collection.name}${buildFilter(mixed)};`)
        .then(rows => rows[0].count)
        .catch(handleError(`Failed to count documents for '${collectionId(collection)}${formatMixed(mixed)}'`, 0, opts))
}

async function query<T = any>(collection: Collection, q: string): Promise<T[]> {
    const res = await collection.scope.query<T>(q)
    return res.rows
}

const buildFilter = (mixed: MixedCollection | null): string => mixed ? ` WHERE ${mixed.attribute}='${mixed.value}'` : ''
const collectionId = (collection: Collection): string => `${collection.scope.bucket.name}.${collection.scope.name}.${collection.name}`
const formatMixed = (mixed: MixedCollection | null) => mixed ? `(${mixed.attribute}=${mixed.value})` : ''
