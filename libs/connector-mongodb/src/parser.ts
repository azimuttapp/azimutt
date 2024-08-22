import {ObjectId} from "mongodb";
import {removeUndefined} from "@azimutt/utils";

export type ParsedMongoStatement = {
    database?: string | undefined
    collection: string
    operation: string
    command: unknown
    projection?: unknown | undefined
    limit?: number | undefined
}

export function parseMongoStatement(statement: string): ParsedMongoStatement | string {
    const legacy = legacyParseStatement(statement)
    if (typeof legacy !== 'string') return legacy

    const dbRegex = 'db(?:\\(["\']([^"\']+)["\']\\))?'
    const collectionRegex = '(?:([^.(]+)|collection\\(["\']([^"\']+)["\']\\))'
    const operationRegex = '([^(]+)'
    const commandRegex = '([\\s\\S]*?)'
    const projectionRegex = '\\.project\\(([^(]+)\\)'
    const limitRegex = '\\.limit\\((\\d+)\\)'
    const regex = new RegExp(`^${dbRegex}\\.${collectionRegex}\\.${operationRegex}\\(${commandRegex}\\)(?:${projectionRegex})?(?:${limitRegex})?;?$`, 'i')
    const [, database, collection, collection2, operation, commandStr, projectionStr, limitStr] = statement.trim().match(regex) || []

    const command = commandStr ? parseCommand(commandStr) : {}
    const projection = projectionStr ? safeParse(projectionStr) || `Invalid projection (${projectionStr})` : undefined
    if (!(collection || collection2)) return `Invalid query (${statement}), in should be in form of: 'db.$collection.$operation($command);', ex: 'db.users.find({});'`
    if (!command) {
        const [, badLimit] = commandStr.match(/\.limit\(([^)]*)$/) || []
        if (badLimit) return `Invalid limit (${badLimit}), should be a number`
        if (commandStr.startsWith('Object')) return `Invalid ObjectId (${commandStr}), should be like: ObjectId("66ae842903c5dc4e5bd14a00")`
        return `Invalid command (${commandStr}), should be a valid JSON`
    }
    if (typeof projection === 'string') return projection

    return removeUndefined({
        database,
        collection: collection || collection2,
        operation,
        command,
        projection,
        limit: limitStr ? parseInt(limitStr) : undefined
    })
}

function parseCommand(command: string): ObjectId | unknown {
    const [, id] = command.trim().match(/^ObjectId\(["']([0-9a-f]{24})["']\)$/) || []
    return id ? new ObjectId(id) : safeParse(command)
}

export function legacyParseStatement(statement: string): ParsedMongoStatement | string {
    const [database, collection, operation, commandStr, limitStr] = statement.split('/').map(v => v.trim())
    const command = safeParse(commandStr)
    const limit = limitStr ? parseInt(limitStr) : undefined
    if (!collection) return 'Missing collection name (legacy mode)'
    if (!operation) return 'Missing operation name (legacy mode)'
    if (!commandStr) return 'Missing command (legacy mode)'
    if (!command) return `Invalid command (${commandStr}), it should be a valid JSON (legacy mode)`
    if (limitStr && !limit) return `Invalid limit (${limitStr}), it should be a number (legacy mode)`
    return removeUndefined({
        database: database || undefined,
        collection,
        operation,
        command,
        limit: limit || undefined
    })
}

function safeParse(json: string): any | undefined {
    try {
        return JSON.parse(json)
    } catch {
        return undefined
    }
}
