import {isNotUndefined, maxLen, removeUndefined} from "@azimutt/utils";
import {EntityRef} from "../database";

export function getMainEntity(sql: string): EntityRef | undefined {
    const res = sql.match(new RegExp(insertRegex, 'i'))
        || sql.match(new RegExp(updateRegex, 'i'))
        || sql.match(new RegExp(deleteRegex, 'i'))
        || sql.match(new RegExp(fromRegex, 'i'))
    return res ? extractEntityRegex(res) : undefined
}

export function getEntities(sql: string): EntityRef[] {
    const lower = sql.trim().toLowerCase()
    const matches = lower.startsWith('insert') ? [...sql.matchAll(new RegExp(insertRegex, 'gi'))] :
        lower.startsWith('update') ? [...sql.matchAll(new RegExp(updateRegex, 'gi'))] :
            lower.startsWith('delete') ? [...sql.matchAll(new RegExp(deleteRegex, 'gi'))] :
                lower.startsWith('select') ? [...sql.matchAll(new RegExp(fromRegex, 'gi')), ...sql.matchAll(new RegExp(joinRegex, 'gi'))] : []
    return matches.map(extractEntityRegex).filter(isNotUndefined)
}

const identifierRegex = `["'\`\\[]?\\b\\w+\\b["'\`\\]]?`
const entityRegex = `(?:${identifierRegex}\\.)?${identifierRegex}`
const insertRegex = `^INSERT\\s+INTO\\s+(${entityRegex})(?:\\s|\\()`
const updateRegex = `^UPDATE\\s+(${entityRegex})\\s`
const deleteRegex = `^DELETE\\s+FROM\\s+(${entityRegex})\\s`
const fromRegex = `\\s+FROM\\s+(${entityRegex})(?:\\s|;)`
const joinRegex = `\\s+JOIN\\s+(${entityRegex})\\s`

function extractEntityRegex(res: RegExpMatchArray | RegExpExecArray): EntityRef | undefined {
    const [, value] = res
    const [entity, schema] = value?.replaceAll(/["'`\[\]]/g, '')?.split('.')?.reverse() || []
    return entity ? removeUndefined({entity, schema}) : undefined
}

export function formatSql(sql: string): string {
    const maxLength = 200
    const singleLine = sql.trim().split('\n')
        .map(line => line.replaceAll(/\s+/g, ' ').replaceAll(/--.*/g, '').trim())
        .map((line, i) => i === 0 || line.startsWith(',') ? line : ' ' + line)
        .join('')
    if (singleLine.length > maxLength) {
        const [, select, other] = singleLine.match(/^SELECT\s+(.+)\s+FROM(.*)/) || []
        return maxLen(select ? `SELECT ${maxLen(select, 40)} FROM${other}` : singleLine, maxLength)
    } else {
        return singleLine
    }
}
