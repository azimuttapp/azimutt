import chalk from "chalk";
import * as mongodb from "./mongodb";
import * as couchbase from "./couchbase";
import * as postgres from "./postgres";
import {DbKind, DbUrl} from "../utils/database";
import {log, warn} from "../utils/logger";
import {FileFormat, FilePath, writeJsonFile} from "../utils/file";

export type Opts = {
    kind: DbKind | undefined
    database: string | undefined
    schema: string | undefined
    bucket: string | undefined
    sampleSize: number
    rawSchema: boolean
    flatten: number
    inferRelations: boolean
    format: FileFormat
    output: FilePath | undefined
}

export async function exportDbSchema(url: DbUrl, opts: Opts): Promise<void> {
    log(`Exporting database schema from ${url.full}...`)
    const kind = opts.kind || url.kind
    if (kind === 'mongodb') {
        if (opts.format !== 'json') {
            return warn(`Only 'json' format is supported for MongoDB.`)
        }
        log('MongoDB database recognized...')
        const mongoSchema = await mongodb.exportSchema(url.full, opts.database || url.db, opts.sampleSize)
        const azimuttSchema = mongodb.transformSchema(mongoSchema, opts.flatten, opts.inferRelations)
        const schemas: string[] = [...new Set(azimuttSchema.tables.map(t => t.schema))]
        const file = filename(opts.output, url, schemas, opts.format)
        log(`Writing schema to ${file} file...`)
        await writeJsonFile(file, azimuttSchema)
        opts.rawSchema && await writeJsonFile(file.replace('.json', `.${kind}.json`), mongoSchema)
        log('')
        log(chalk.green(`MongoDB schema written in '${file}'.`))
        log(`Found ${azimuttSchema.tables.length} collections in ${schemas.length} databases.`)
        log('You can now import this file in ▶︎https://azimutt.app/new?json ◀︎︎')
    } else if (kind === 'couchbase') {
        if (opts.format !== 'json') {
            return warn(`Only 'json' format is supported for Couchbase.`)
        }
        log('Couchbase database recognized...')
        const couchbaseSchema = await couchbase.exportSchema(url, opts.bucket || url.db, opts.sampleSize)
        const azimuttSchema = couchbase.transformSchema(couchbaseSchema, opts.flatten, opts.inferRelations)
        const schemas: string[] = [...new Set(azimuttSchema.tables.map(t => t.schema))]
        const file = filename(opts.output, url, schemas, opts.format)
        log(`Writing schema to ${file} file...`)
        await writeJsonFile(file, azimuttSchema)
        opts.rawSchema && await writeJsonFile(file.replace('.json', `.${kind}.json`), couchbaseSchema)
        log('')
        log(chalk.green(`Couchbase schema written in '${file}'.`))
        log(`Found ${azimuttSchema.tables.length} collections in ${schemas.length} buckets.`)
        log('You can now import this file in ▶︎https://azimutt.app/new?json ◀︎︎')
    } else if (kind === 'postgres') {
        if (opts.format !== 'json') { // FIXME handle 'sql' format using pg_dump
            return warn(`Only 'json' format is supported for PostgreSQL.`)
        }
        log('PostgreSQL database recognized...')
        const postgresSchema = await postgres.exportSchema(url.full, opts.schema, opts.sampleSize)
        const azimuttSchema = postgres.transformSchema(postgresSchema, opts.flatten, opts.inferRelations)
        const schemas: string[] = [...new Set(azimuttSchema.tables.map(t => t.schema))]
        const file = filename(opts.output, url, schemas, opts.format)
        log(`Writing schema to ${file} file...`)
        await writeJsonFile(file, azimuttSchema)
        opts.rawSchema && await writeJsonFile(file.replace('.json', `.${kind}.json`), postgresSchema)
        log('')
        log(chalk.green(`PostgreSQL schema written in '${file}'.`))
        log(`Found ${azimuttSchema.tables.length} tables in ${schemas.length} schemas.`)
        log('You can now import this file in ▶︎https://azimutt.app/new?json ◀︎︎')
    } else {
        log('')
        warn(chalk.red(`Database kind '${url.kind}' is not supported :(`))
        log(`But you're welcome to send an issue or PR at https://github.com/azimuttapp/azimutt ;)`)
    }
}

function filename(output: FilePath | undefined, url: DbUrl, schemas: string[], format: FileFormat): string {
    return output || `${url.db || (schemas.length === 1 ? schemas[0] : undefined) || 'azimutt'}-${new Date().toISOString().substring(0, 19)}.${format}`
}
