import chalk from "chalk";
import {Connector, DatabaseKind, DatabaseUrlParsed} from "@azimutt/database-types";
import {couchbase} from "@azimutt/connector-couchbase";
import {mongodb} from "@azimutt/connector-mongodb";
import {postgres} from "@azimutt/connector-postgres";
import {FileFormat, FilePath, writeJsonFile} from "./utils/file";
import {logger} from "./utils/logger";

export type Opts = {
    database: string | undefined
    schema: string | undefined
    bucket: string | undefined
    mixedCollection: string | undefined
    sampleSize: number
    inferRelations: boolean
    format: FileFormat
    output: FilePath | undefined
}

export async function exportDbSchema(kind: DatabaseKind, url: DatabaseUrlParsed, opts: Opts): Promise<void> {
    logger.log(`Exporting database schema from ${url.full} ...`)
    if (kind !== url.kind) {
        logger.warn(`${kind} not recognized from url (got ${JSON.stringify(url.kind)}), will try anyway but expect some errors...`)
    }
    if (kind === 'couchbase') {
        await exportJsonSchema(kind, url, opts, couchbase)
    } else if (kind === 'mongodb') {
        await exportJsonSchema(kind, url, opts, mongodb)
    } else if (kind === 'postgres') {
        // TODO handle 'sql' format using pg_dump
        await exportJsonSchema(kind, url, opts, postgres)
    } else {
        logger.log('')
        logger.error(`Source kind '${kind}' is not supported :(`)
        logger.log(`But you're welcome to send an issue or PR at https://github.com/azimuttapp/azimutt ;)`)
    }
}

async function exportJsonSchema(kind: DatabaseKind, url: DatabaseUrlParsed, opts: Opts, connector: Connector) {
    if (opts.format !== 'json') {
        return logger.error(`Unsupported format '${opts.format}' for ${connector.name}, try 'json'.`)
    }
    const azimuttSchema = await connector.getSchema('azimutt-cli', url, {
        logger,
        schema: opts.database || opts.bucket || opts.schema,
        mixedCollection: opts.mixedCollection,
        sampleSize: opts.sampleSize,
        inferRelations: opts.inferRelations
    })
    const schemas: string[] = [...new Set(azimuttSchema.tables.map(t => t.schema))]
    const file = filename(opts.output, url, schemas, opts.format)
    logger.log(`Writing schema to ${file} file ...`)
    await writeJsonFile(file, azimuttSchema)
    logger.log('')
    logger.log(chalk.green(`${connector.name} schema written in '${file}'.`))
    logger.log(`Found ${azimuttSchema.tables.length} tables in ${schemas.length} schemas.`)
    logger.log('You can now import this file in ▶︎ https://azimutt.app/new?json ◀︎︎')
}

function filename(output: FilePath | undefined, url: DatabaseUrlParsed, schemas: string[], format: FileFormat): string {
    return output || `${url.db || (schemas.length === 1 ? schemas[0] : undefined) || 'azimutt'}-${new Date().toISOString().substring(0, 19)}.${format}`
}
