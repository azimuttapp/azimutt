import chalk from "chalk";
import {Connector, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {getConnector} from "@azimutt/gateway";
import {FileFormat, FilePath, writeJsonFile} from "./utils/file.js";
import {logger} from "./utils/logger.js";

export type Opts = {
    database: string | undefined
    schema: string | undefined
    bucket: string | undefined
    mixedCollection: string | undefined
    sampleSize: number
    inferRelations: boolean
    ignoreErrors: boolean
    logQueries: boolean
    format: FileFormat
    output: FilePath | undefined
}

export async function exportDbSchema(url: string, opts: Opts): Promise<void> {
    logger.log(`Exporting database schema from ${url} ...`)
    const parsedUrl = parseDatabaseUrl(url)
    const connector = getConnector(parsedUrl)
    if (connector) {
        await exportJsonSchema(parsedUrl, opts, connector)
    } else {
        logger.log('')
        if (parsedUrl.kind) {
            logger.error(`${parsedUrl.kind} database is not supported yet :(`)
        } else {
            logger.error(`Can't recognize database :(`)
        }
        logger.log(`But you're welcome to send an issue or PR at https://github.com/azimuttapp/azimutt ;)`)
    }
}

async function exportJsonSchema(url: DatabaseUrlParsed, opts: Opts, connector: Connector) {
    if (opts.format !== 'json') {
        return logger.error(`Unsupported format '${opts.format}' for ${connector.name}, try 'json'.`)
    }
    const start = Date.now()
    const azimuttSchema = await connector.getSchema('azimutt-cli', url, {
        logger,
        logQueries: opts.logQueries,
        schema: opts.database || opts.bucket || opts.schema,
        mixedCollection: opts.mixedCollection,
        sampleSize: opts.sampleSize,
        inferRelations: opts.inferRelations,
        ignoreErrors: opts.ignoreErrors
    })
    logger.log(`Export done in ${Date.now() - start} ms.`)
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
    const schema = (schemas.length === 1 ? schemas[0] : undefined) || 'azimutt'
    const date = new Date().toISOString().substring(0, 19)
    return output || `${url.db || schema}-${date}.${format}`.replaceAll(':', '_') // avoid ':' as it's invalid filename char in Windows
}
