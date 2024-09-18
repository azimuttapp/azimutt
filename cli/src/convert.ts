import {Result} from "@azimutt/utils";
import {
    Database,
    databaseJsonFormat,
    databaseJsonParse,
    ParserError,
    ParserResult,
    TokenEditor,
    zodParse
} from "@azimutt/models";
import {parseAml, generateAml} from "@azimutt/aml";
import {fileRead, fileWrite} from "./utils/file.js";
import {logger} from "./utils/logger.js";

export type Opts = {
    from: string
    to: string
    out?: string | undefined
}

export async function convertFile(path: string, opts: Opts): Promise<void> {
    logger.log(`Convert ${path} from ${opts.from} to ${opts.to}...`)
    logger.log(`Reading to ${path}...`)
    const content = await fileRead(path)
    logger.log(`Parsing ${opts.from} content...`)
    const parsed = parseDialect(opts.from, content)
    parsed.errors?.forEach(err => logger.error(`Parsing ${err.kind}: ${err.message}${showPosition(err.position)}`))
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
    if (dialect === 'json') return databaseJsonParse(content)
    return ParserResult.failure([parserError('BadArgument', `Can't parse ${dialect} dialect`)])
}

function generateDialect(dialect: string, db: Database): Result<string, string> {
    if (dialect === 'aml') return Result.success(generateAml(db))
    if (dialect === 'json') return Result.success(databaseJsonFormat(db) + '\n')
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

function parserError(name: string, message: string): ParserError {
    return {name, kind: 'error', message, offset: {start: 0, end: 0}, position: {start: {line: 0, column: 0}, end: {line: 0, column: 0}}}
}

function showPosition(pos: TokenEditor): string {
    return pos.start.line === 0 ? '' : ` at line ${pos.start.line}, column ${pos.start.column}`
}
