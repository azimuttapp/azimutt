import chalk from "chalk";
import * as mongodb from "./mongodb";
import * as couchbase from "./couchbase";
import * as postgres from "./postgres";
import {AzimuttSchema, DbKind, DbUrl} from "../utils/database";
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
    log(`Exporting database schema from ${url.full} ...`)
    const kind = opts.kind || url.kind
    if (opts.kind && opts.kind !== url.kind) {
        warn(chalk.yellow(`${opts.kind} not recognized from url (got ${JSON.stringify(url.kind)}), will try anyway but expect some errors.`))
    }
    if (kind === 'mongodb') {
        await exportJsonSchema(url, opts, mongodb.fetchSchema, mongodb.transformSchema, 'MongoDB')
    } else if (kind === 'couchbase') {
        await exportJsonSchema(url, opts, couchbase.fetchSchema, couchbase.transformSchema, 'Couchbase')
    } else if (kind === 'postgres') {
        // TODO handle 'sql' format using pg_dump
        await exportJsonSchema(url, opts, postgres.fetchSchema, postgres.transformSchema, 'PostgreSQL')
    } else {
        log('')
        warn(chalk.red(`Database kind '${url.kind}' is not supported :(`))
        log(`But you're welcome to send an issue or PR at https://github.com/azimuttapp/azimutt ;)`)
    }
}

async function exportJsonSchema<T extends object>(url: DbUrl, opts: Opts, fetchSchema: (url: DbUrl, schema: string | undefined, sampleSize: number) => Promise<T>, transformSchema: (s: T, flatten: number, inferRelations: boolean) => AzimuttSchema, name: string) {
    if (opts.format !== 'json') {
        return warn(chalk.red(`Unsupported format '${opts.format}' for ${name}, try 'json'.`))
    }
    log(`${name} database recognized ...`)
    const rawSchema = await fetchSchema(url, opts.database || opts.bucket || opts.schema, opts.sampleSize)
    const azimuttSchema = transformSchema(rawSchema, opts.flatten, opts.inferRelations)
    const schemas: string[] = [...new Set(azimuttSchema.tables.map(t => t.schema))]
    const file = filename(opts.output, url, schemas, opts.format)
    log(`Writing schema to ${file} file ...`)
    await writeJsonFile(file, azimuttSchema)
    opts.rawSchema && await writeJsonFile(file.replace('.json', `.${opts.kind || url.kind}.json`), rawSchema)
    log('')
    log(chalk.green(`${name} schema written in '${file}'.`))
    log(`Found ${azimuttSchema.tables.length} tables in ${schemas.length} schemas.`)
    log('You can now import this file in ▶︎https://azimutt.app/new?json ◀︎︎')
}

function filename(output: FilePath | undefined, url: DbUrl, schemas: string[], format: FileFormat): string {
    return output || `${url.db || (schemas.length === 1 ? schemas[0] : undefined) || 'azimutt'}-${new Date().toISOString().substring(0, 19)}.${format}`
}
