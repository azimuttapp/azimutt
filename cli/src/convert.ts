import {Result} from "@azimutt/utils";
import {
    Database,
    generateJsonDatabase,
    parseJsonDatabase,
    ParserError,
    ParserErrorLevel,
    ParserResult,
    TokenEditor
} from "@azimutt/models";
import {generateAml, parseAml} from "@azimutt/aml";
import {generateSql, parseSql} from "@azimutt/parser-sql";
import {track} from "@azimutt/gateway";
import {fileRead, fileWrite} from "./utils/file.js";
import {logger} from "./utils/logger.js";
import {version} from "./version.js";

export type Opts = {
    from: string
    to: string
    out?: string | undefined
}

export async function convertFile(path: string, opts: Opts): Promise<void> {
    logger.log(`Convert ${path} from ${opts.from} to ${opts.to}...`)
    logger.log(`Reading to ${path}...`)
    const content = await fileRead(path)
    track('cli__convert__run', {version, from: opts.from, to: opts.to, length: content.length}, 'cli').then(() => {})
    logger.log(`Parsing ${opts.from} content...`)
    const parsed = parseDialect(opts.from, content)
    parsed.errors?.forEach(err => logger.error(`Parsing ${err.level}: ${err.message} (${err.kind})${showPosition(err.position)}`))
    if (!parsed.result) {
        logger.error(`Unable to parse ${path} content as ${opts.from}`)
        return
    }
    logger.log(`Generating ${opts.to} content...`)
    await generateDialect(opts.to, parsed.result).fold(async outContent => {
        const outPath = opts.out || buildOutPath(path, opts.to)
        logger.log(`Writing to ${outPath}...`)
        await fileWrite(outPath, outContent)
    }, async err => logger.error(`Generation error: ${err}`))
    logger.log(`Done 👍️\n`)
}

function parseDialect(dialect: string, content: string): ParserResult<Database> {
    if (dialect === 'aml') return parseAml(content)
    if (dialect === 'postgres') return parseSql(content, 'postgres')
    if (dialect === 'json') return parseJsonDatabase(content)
    return ParserResult.failure([parserError(`Can't parse ${dialect} dialect`, 'BadArgument')])
}

function generateDialect(dialect: string, db: Database): Result<string, string> {
    if (dialect === 'aml') return Result.success(generateAml(db))
    if (dialect === 'postgres') return Result.success(generateSql(db, 'postgres'))
    if (dialect === 'json') return Result.success(generateJsonDatabase(db))
    return Result.failure(`Can't generate ${dialect} dialect`)
}

function buildOutPath(path: string, dialect: string): string {
    const [, file, ext] = path.match(/(.*)\.([a-z]+)$/) || []
    const outExt = dialectToExtension(dialect)
    if (!file) return `${path}.${outExt}`
    if (outExt === ext) return `${file}.out.${outExt}`
    return `${file}.${outExt}`
}

function dialectToExtension(dialect: string): string {
    if (dialect === 'aml') return 'md'
    if (dialect === 'json') return 'json'
    return 'txt'
}

function parserError(message: string, kind: string): ParserError {
    return {message, kind, level: ParserErrorLevel.enum.error, offset: {start: 0, end: 0}, position: {start: {line: 0, column: 0}, end: {line: 0, column: 0}}}
}

function showPosition(pos: TokenEditor): string {
    return pos.start.line === 0 ? '' : ` at line ${pos.start.line}, column ${pos.start.column}`
}
