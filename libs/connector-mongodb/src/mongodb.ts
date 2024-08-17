import {Collection, Filter} from "mongodb";
import {joinLimit, pluralizeL, removeUndefined, sequence} from "@azimutt/utils";
import {
    AttributeName,
    AttributeValue,
    ConnectorSchemaOpts,
    connectorSchemaOptsDefaults,
    Database,
    DatabaseKind,
    DatabaseName,
    Entity,
    formatConnectorScope,
    handleError,
    schemaToAttributes,
    valuesToSchema
} from "@azimutt/models";
import {scopeFilter} from "./helpers";
import {Conn} from "./connect";

export const getSchema = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<Database> => {
    const start = Date.now()
    const scope = formatConnectorScope({database: 'database', entity: 'collection'}, opts)
    opts.logger.log(`Connected to the database${scope ? `, exporting for ${scope}` : ''} ...`)
    const databaseNames: DatabaseName[] = await getDatabases(opts)(conn)
    opts.logger.log(`Found ${pluralizeL(databaseNames, 'database')} to export (${joinLimit(databaseNames)}) ...`)
    const collections: Collection[] = await getCollections(databaseNames, opts)(conn)
    opts.logger.log(`Found ${pluralizeL(collections, 'collection')} to export (${joinLimit(collections.map(c => c.collectionName))}) ...`)
    const entities: Entity[] = (await sequence(collections, collection => inferCollection(collection, opts))).flat()
    opts.logger.log(`✔︎ Exported ${pluralizeL(entities, 'collection')} from the database!`)
    return removeUndefined({
        entities: entities,
        relations: undefined,
        types: undefined,
        doc: undefined,
        stats: removeUndefined({
            name: conn.url.db,
            kind: DatabaseKind.Enum.mongodb,
            version: undefined,
            doc: undefined,
            extractedAt: new Date().toISOString(),
            extractionDuration: Date.now() - start,
            size: undefined,
        }),
        extra: undefined,
    })
}

// 👇️ Private functions, some are exported only for tests
// If you use them, beware of breaking changes!

const getDatabases = (opts: ConnectorSchemaOpts) => (conn: Conn): Promise<DatabaseName[]> => {
    if (opts.database && !opts.database.includes('%')) {
        return Promise.resolve([opts.database])
    } else {
        const adminDb = conn.underlying.db('admin')
        return adminDb.admin().listDatabases().then(dbs =>
            dbs.databases.map(db => db.name).filter(name => scopeFilter({database: name}, opts))
        ).catch(handleError(`Failed to get databases`, [], opts))
    }
}

const getCollections = (databaseNames: DatabaseName[], opts: ConnectorSchemaOpts) => (conn: Conn): Promise<Collection[]> => {
    return sequence(databaseNames, dbName => conn.underlying.db(dbName).collections())
        .then(cols => cols.flat().filter(c => scopeFilter({entity: c.collectionName}, opts)))
        .catch(handleError(`Failed to get collections`, [], opts))
}

// TODO: allow nested attribute
type MixedCollection = {attribute: AttributeName, value: string}

async function inferCollection(collection: Collection, opts: ConnectorSchemaOpts): Promise<Entity[]> {
    // FIXME: fetch index informations & more
    // console.log('options', await collection.options()) // empty
    // console.log('indexes', await collection.indexes())
    // console.log('listIndexes', await collection.listIndexes().toArray()) // same result as indexes()
    // console.log('indexInformation', await collection.indexInformation()) // not much
    // console.log('stats', await collection.stats()) // several info
    opts.logger.log(`Exporting collection ${collectionId(collection)} ...`)
    if (opts.inferMixedJson) {
        const attribute: AttributeName = opts.inferMixedJson
        const values = await getDistinctValues(collection, attribute, opts)
            .then(values => values.filter((v): v is string => typeof v === 'string'))
        if (values.length > 0) {
            opts.logger.log(`  Found ${pluralizeL(values, 'kind')} to export (${joinLimit(values)}) ...`)
            return sequence(values, value => {
                opts.logger.log(`  Exporting collection ${collectionId(collection)} for ${attribute}=${value} ...`)
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
    return collection.distinct(attribute)
        .catch(handleError(`Failed to get distinct values for '${collectionId(collection)}(${attribute})'`, [], opts))
}

async function inferCollectionMixed(collection: Collection, mixed: MixedCollection | null, opts: ConnectorSchemaOpts): Promise<Entity> {
    const documents = await getSampleDocuments(collection, mixed, opts)
    const attrs = schemaToAttributes(valuesToSchema(documents))
    const pk = attrs.find(a => a.name === '_id')
    const count = await countDocuments(collection, mixed, opts)
    return removeUndefined({
        schema: collection.dbName,
        name: mixed ? `${collection.collectionName}__${mixed.attribute}__${mixed.value}` : collection.collectionName,
        kind: undefined,
        def: undefined,
        attrs,
        pk: pk ? removeUndefined({name: undefined, attrs: [[pk.name]], doc: undefined, stats: undefined, extra: undefined}) : undefined,
        indexes: undefined,
        checks: undefined,
        doc: undefined,
        stats: removeUndefined({
            rows: count,
            size: undefined,
            sizeIdx: undefined,
            sizeToast: undefined,
            sizeToastIdx: undefined,
            scanSeq: undefined,
            scanSeqLast: undefined,
            scanIdx: undefined,
            scanIdxLast: undefined,
            analyzeLast: undefined,
            vacuumLast: undefined,
        }),
        extra: undefined
    })
}

type CollectionDoc = any

async function getSampleDocuments(collection: Collection, mixed: MixedCollection | null, opts: ConnectorSchemaOpts): Promise<CollectionDoc[]> {
    // TODO: use $sample: https://www.mongodb.com/docs/manual/reference/operator/aggregation/sample
    const sampleSize = opts.sampleSize || connectorSchemaOptsDefaults.sampleSize
    return collection.find(buildFilter(mixed)).limit(sampleSize).toArray()
        .catch(handleError(`Failed to get sample documents for '${collectionId(collection)}${formatMixed(mixed)}'`, [], opts))
}

async function countDocuments(collection: Collection, mixed: MixedCollection | null, opts: ConnectorSchemaOpts): Promise<number> {
    return collection.countDocuments(buildFilter(mixed))
        .catch(handleError(`Failed to count documents for '${collectionId(collection)}${formatMixed(mixed)}'`, 0, opts))
}

const buildFilter = (mixed: MixedCollection | null): Filter<any> => mixed ? {[mixed.attribute]: mixed.value} : {}
const collectionId = (collection: Collection): string => `${collection.dbName}.${collection.collectionName}`
const formatMixed = (mixed: MixedCollection | null) => mixed ? `(${mixed.attribute}=${mixed.value})` : ''
