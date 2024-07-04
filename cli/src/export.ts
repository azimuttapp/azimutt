import chalk from "chalk";
import {isNotUndefined, pluralizeL} from "@azimutt/utils";
import {Connector, databaseToLegacy, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {getConnector} from "@azimutt/gateway";
import {FileFormat, FilePath, fileWriteJson} from "./utils/file.js";
import {logger} from "./utils/logger.js";

export type Opts = {
    database: string | undefined
    catalog: string | undefined
    schema: string | undefined
    entity: string | undefined
    bucket: string | undefined
    sampleSize: number
    mixedJson: string | undefined
    inferJsonAttributes: boolean
    inferPolymorphicRelations: boolean
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
    const database = await connector.getSchema('azimutt-cli', url, {
        logger,
        logQueries: opts.logQueries,
        database: opts.database,
        catalog: opts.catalog,
        schema: opts.bucket || opts.schema,
        entity: opts.entity,
        sampleSize: opts.sampleSize,
        inferMixedJson: opts.mixedJson,
        inferJsonAttributes: opts.inferJsonAttributes,
        inferPolymorphicRelations: opts.inferPolymorphicRelations,
        inferRelationsFromJoins: true,
        inferPii: true,
        inferRelations: opts.inferRelations,
        ignoreErrors: opts.ignoreErrors
    })
    logger.log(`Export done in ${Date.now() - start} ms.`)
    const schemas: string[] = [...new Set(database.entities?.map(t => t.schema)?.filter(isNotUndefined))]
    const file = filename(opts.output, url, schemas, opts.format)
    logger.log(`Writing schema to ${file} file ...`)
    await fileWriteJson(file, databaseToLegacy(database))
    logger.log('')
    logger.log(chalk.green(`${connector.name} schema written in '${file}'.`))
    logger.log(`Found ${pluralizeL(database.entities || [], 'table')} in ${pluralizeL(schemas, 'schema')}.`)
    logger.log('You can now import this file in ▶︎ https://azimutt.app/new?json ◀︎︎')
}

function filename(output: FilePath | undefined, url: DatabaseUrlParsed, schemas: string[], format: FileFormat): string {
    const schema = (schemas.length === 1 ? schemas[0] : undefined) || 'azimutt'
    const date = new Date().toISOString().substring(0, 19)
    return output || `${url.db || schema}-${date}.${format}`.replaceAll(':', '_') // avoid ':' as it's invalid filename char in Windows
}
