import chalk from "chalk";
import {AzimuttSchema, DatabaseUrlParsed, DatabaseKind} from "@azimutt/database-types";
import * as couchbase from "@azimutt/connector-couchbase";
import * as mongodb from "@azimutt/connector-mongodb";
import * as postgres from "@azimutt/connector-postgres";
import {Logger} from "@azimutt/utils";
import {logger} from "../utils/logger";
import {FileFormat, FilePath, writeJsonFile} from "../utils/file";

export type Opts = {
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

export async function exportDbSchema(kind: DatabaseKind, url: DatabaseUrlParsed, opts: Opts): Promise<void> {
    logger.log(`Exporting database schema from ${url.full} ...`)
    if (kind !== url.kind) {
        logger.warn(`${kind} not recognized from url (got ${JSON.stringify(url.kind)}), will try anyway but expect some errors...`)
    }
    if (kind === 'mongodb') {
        await exportJsonSchema(kind, url, opts, mongodb.fetchSchema, mongodb.transformSchema, 'MongoDB')
    } else if (kind === 'couchbase') {
        await exportJsonSchema(kind, url, opts, couchbase.fetchSchema, couchbase.transformSchema, 'Couchbase')
    } else if (kind === 'postgres') {
        // TODO handle 'sql' format using pg_dump
        await exportJsonSchema(kind, url, opts, postgres.fetchSchema, postgres.transformSchema, 'PostgreSQL')
    } else {
        logger.log('')
        logger.error(`Source kind '${kind}' is not supported :(`)
        logger.log(`But you're welcome to send an issue or PR at https://github.com/azimuttapp/azimutt ;)`)
    }
}

async function exportJsonSchema<T extends object>(
    kind: DatabaseKind,
    url: DatabaseUrlParsed,
    opts: Opts,
    fetchSchema: (url: DatabaseUrlParsed, schema: string | undefined, sampleSize: number, logger: Logger) => Promise<T>,
    transformSchema: (s: T, flatten: number, inferRelations: boolean) => AzimuttSchema,
    name: string
) {
    if (opts.format !== 'json') {
        return logger.error(`Unsupported format '${opts.format}' for ${name}, try 'json'.`)
    }
    const rawSchema = await fetchSchema(url, opts.database || opts.bucket || opts.schema, opts.sampleSize, logger)
    const azimuttSchema = transformSchema(rawSchema, opts.flatten, opts.inferRelations)
    const schemas: string[] = [...new Set(azimuttSchema.tables.map(t => t.schema))]
    const file = filename(opts.output, url, schemas, opts.format)
    logger.log(`Writing schema to ${file} file ...`)
    await writeJsonFile(file, azimuttSchema)
    opts.rawSchema && await writeJsonFile(file.replace('.json', `.${kind}.json`), rawSchema)
    logger.log('')
    logger.log(chalk.green(`${name} schema written in '${file}'.`))
    logger.log(`Found ${azimuttSchema.tables.length} tables in ${schemas.length} schemas.`)
    logger.log('You can now import this file in ▶︎ https://azimutt.app/new?json ◀︎︎')
}

function filename(output: FilePath | undefined, url: DatabaseUrlParsed, schemas: string[], format: FileFormat): string {
    return output || `${url.db || (schemas.length === 1 ? schemas[0] : undefined) || 'azimutt'}-${new Date().toISOString().substring(0, 19)}.${format}`
}
