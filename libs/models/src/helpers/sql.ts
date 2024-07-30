import {isNotUndefined, maxLen, removeEmpty, removeUndefined} from "@azimutt/utils";
import {EntityRef} from "../database";
import {removeQuotes} from "../databaseUtils";

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

// (basic) SQL Parser

export type ParsedSqlScript = ParsedSqlStatement[]
export type ParsedSqlStatement = ParsedSelectStatement
export type ParsedSelectStatement = {command: 'SELECT', table: ParsedSelectTable, columns: ParsedSelectColumn[], joins?: ParsedSelectJoin[], where?: ParsedSelectWhere, groupBy?: ParsedSelectGroupBy, having?: ParsedSelectHaving, orderBy?: ParsedSelectOrderBy, offset?: ParsedSelectOffset, limit?: ParsedSelectLimit}
export type ParsedSelectTable = {name: string, schema?: string, alias?: string}
export type ParsedSelectColumn = {name: string, scope?: string, col?: string[], def?: string}
export type ParsedSelectJoin = {table: string, schema?: string, alias?: string, kind?: 'INNER' | 'LEFT' | 'RIGHT' | 'FULL', on?: ParsedSqlCondition}
export type ParsedSelectWhere = ParsedSqlCondition
export type ParsedSelectGroupBy = string // TODO
export type ParsedSelectHaving = ParsedSqlCondition
export type ParsedSelectOrderBy = string // TODO
export type ParsedSelectOffset = number
export type ParsedSelectLimit = number
export type ParsedSqlCondition = ParsedSqlConditionBool | ParsedSqlConditionExp | ParsedSqlConditionNull | ParsedSqlConditionIn | string
export type ParsedSqlConditionBool = { op: 'AND' | 'OR', left: ParsedSqlCondition, right: ParsedSqlCondition }
export type ParsedSqlConditionExp = { op: '=' | '!=' | '>' | '>=' | '<' | '<=' | '<>' | 'LIKE', left: ParsedSqlValue, right: ParsedSqlValue }
export type ParsedSqlConditionNull = { op: 'NULL' | 'NOT NULL', value: ParsedSqlValue }
export type ParsedSqlConditionIn = { op: 'IN' | 'NOT IN', value: ParsedSqlValue, values: ParsedSqlValue[] }
export type ParsedSqlValue = {column: string, scope?: string} | string | number

export function parseSqlScript(script: string): ParsedSqlScript {
    return script.split(';').map(s => parseSqlStatement(s.trim() + ';')).filter(s => !!s)
}

export function parseSqlStatement(statement: string): ParsedSqlStatement | undefined {
    if (statement.trim().match(/^SELECT\s+/i)) {
        return parseSelectStatement(statement)
    } else {
        return undefined
    }
}

export function parseSelectStatement(statement: string): ParsedSelectStatement | undefined {
    const selectRegex = 'SELECT(?:\\s+DISTINCT)?\\s+(.+?)'
    const fromRegex = 'FROM\\s+(.+?)'
    const whereRegex = 'WHERE\\s+(.+?)'
    const groupByRegex = 'GROUP\\s+BY\\s+(.+?)'
    const havingRegex = 'HAVING\\s+(.+?)'
    const orderByRegex = 'ORDER\\s+BY\\s+(.+?)'
    const limitRegex = 'LIMIT\\s+(\\d+)'
    const offsetRegex = 'OFFSET\\s+(\\d+)(?:\\s+ROWS?)?'
    const fetchRegex = 'FETCH\\s+(?:FIRST|NEXT)\\s+(\\d+)\\s+ROWS?\\s+ONLY'
    const optRegex = [whereRegex, groupByRegex, havingRegex, orderByRegex, limitRegex, offsetRegex, fetchRegex].map(r => `(?:\\s+${r})?`).join('')
    const regex = new RegExp(`^${selectRegex}\\s+${fromRegex}${optRegex}\\s*;$`, 'i')

    const [, select, from, where, groupBy, having, orderBy, limit, offset, fetch] = statement.trim().match(regex) || []
    const parsedColumns: ParsedSelectColumn[] = (select || '').split(',').map((c, i) => parseSelectColumn(c.trim(), i + 1)).filter(c => !!c)
    const parsedTable: { table: ParsedSelectTable; joins?: ParsedSelectJoin[] } | undefined = parseSelectTable(from || '')
    if (parsedTable && parsedColumns.length > 0) {
        return removeEmpty({
            command: 'SELECT' as const,
            table: parsedTable.table,
            columns: parsedColumns,
            joins: parsedTable.joins,
            where: where && parseCondition(where),
            groupBy,
            having: having && parseCondition(having),
            orderBy,
            offset: offset ? parseInt(offset) : undefined,
            limit: limit ? parseInt(limit) : fetch ? parseInt(fetch) : undefined
        })
    } else {
        return undefined
    }
}

export function parseSelectColumn(column: string, index: number): ParsedSelectColumn | undefined {
    const [, scope, def, alias] = column.match(/^(?:(.+?)\.)?(.+?)(?:\s+AS\s+(.+?))?$/i) || []
    if (def?.match(/^([a-zA-Z0-9_$#]+?|["`].+?["`]?)$/i)) { // simple column
        return removeUndefined({name: removeQuotes(alias || def), scope: scope ? removeQuotes(scope) : undefined, col: [removeQuotes(def)]})
    } else if(def === '*') {
        return removeUndefined({name: '*', scope: scope ? removeQuotes(scope) : undefined})
    } else {
        return removeUndefined({name: removeQuotes(alias || `col_${index}`), def: def ? removeQuotes(def) : undefined})
    }
}

export function parseSelectTable(tables: string): {table: ParsedSelectTable, joins?: ParsedSelectJoin[]} | undefined {
    const [table, ...joins] = tables.replaceAll(/((?:INNER|LEFT|RIGHT|FULL)(?:\s+OUTER)?\s+)?JOIN\s+/gi, 'JOIN $1').split(/JOIN\s+/i) || []
    const [, tableSchema, tableName, tableAlias] = ((table || '').trim().match(/^(?:(.+?)\.)?(.+?)(?:\s+(.+?))?$/i) || []).map(r => r ? removeQuotes(r) : undefined)
    if (tableName) {
        const tableFormatted: ParsedSelectTable = removeUndefined({name: tableName, schema: tableSchema, alias: tableAlias})
        const joinsFormatted: ParsedSelectJoin[] = joins.map(j => {
            const [, kind, schema, table, alias, on] = (j.trim().match(/^((?:INNER|LEFT|RIGHT|FULL)(?:\s+OUTER)?\s+)?(?:(.+?)\.)?(.+?)(?:\s+(.+?))?\s+ON\s+(.+?)$/i) || []).map(r => r ? removeQuotes(r) : undefined)
            return table ? removeUndefined({table, schema, alias, kind: parseSelectJoinKind(kind || ''), on: parseCondition(on || '')}) : undefined
        }).filter(j => !!j)
        return removeEmpty({table: tableFormatted, joins: joinsFormatted})
    } else {
        return undefined
    }
}

export function parseSelectJoinKind(kind: string): ParsedSelectJoin['kind'] | undefined {
    if (kind.match(/^INNER\s+/i)) return 'INNER'
    if (kind.match(/^LEFT\s+/i)) return 'LEFT'
    if (kind.match(/^RIGHT\s+/i)) return 'RIGHT'
    if (kind.match(/^FULL\s+/i)) return 'FULL'
    return undefined
}

export function parseCondition(cond: string): ParsedSqlCondition | undefined {
    if (cond.search(/AND|OR/i) !== -1) {
        return parseConditionBool(cond)
    } else if (cond.search(/[=<>]|\s+LIKE\s+/) !== -1) {
        return parseConditionExp(cond)
    } else if (cond.search(/\s+NULL/i) !== -1) {
        return parseConditionNull(cond)
    } else if (cond.search(/\s+IN\s+\(/i) !== -1) {
        return parseConditionIn(cond)
    } else {
        return cond // can't parse condition yet :/
    }
}

export function parseConditionBool(cond: string): ParsedSqlCondition | ParsedSqlConditionBool | string {
    return cond.replaceAll(/\s+(AND|OR)\s+/gi, '|$1 ').split('|').reduce((acc, item) => {
        if (acc === undefined) {
            return parseCondition(item)
        } else {
            const [, opS, rightS] = item.match(/^(AND|OR)\s+(.+?)$/i) || []
            const op = parseSqlConditionBoolOp(opS)
            const right = parseCondition(rightS)
            return op && right ? {op, left: acc, right} : acc
        }
    }, undefined as ParsedSqlCondition | ParsedSqlConditionBool | undefined) || cond
}

export function parseSqlConditionBoolOp(kind: string): ParsedSqlConditionBool['op'] | undefined {
    if (kind.match(/^AND$/i)) return 'AND'
    if (kind.match(/^OR$/i)) return 'OR'
    return undefined
}

export function parseConditionExp(cond: string): ParsedSqlConditionExp | string {
    const [, leftS, opS, rightS] = cond.match(/^(.+?)\s*(=|!=|>|>=|<|<=|<>|LIKE)\s*(.+?)$/) || []
    const op = parseSqlConditionExpOp(opS || '')
    const left = parseValue(leftS || '')
    const right = parseValue(rightS || '')
    return op && left !== undefined && right !== undefined ? {op, left, right} : cond
}

export function parseSqlConditionExpOp(kind: string): ParsedSqlConditionExp['op'] | undefined {
    if (kind === '=') return kind
    if (kind === '!=') return kind
    if (kind === '>') return kind
    if (kind === '>=') return kind
    if (kind === '<') return kind
    if (kind === '<=') return kind
    if (kind === '<>') return kind
    if (kind === 'LIKE') return kind
    return undefined
}

export function parseConditionNull(cond: string): ParsedSqlConditionNull | string {
    const [, valueS, not] = cond.match(/^(.+?)\s+IS\s+(NOT\s+)?NULL$/i) || []
    const op: ParsedSqlConditionNull['op'] = (not || '').trim().match(/^NOT$/i) ? 'NOT NULL' : 'NULL'
    const value = parseValue(valueS || '')
    return value ? {op, value} : cond
}

export function parseConditionIn(cond: string): ParsedSqlConditionIn | string {
    const [, valueS, not, valuesS] = cond.match(/^(.+?)\s+(NOT\s+)?IN\s+\((.+?)\)$/i) || []
    const op: ParsedSqlConditionIn['op'] = (not || '').trim().match(/^NOT$/i) ? 'NOT IN' : 'IN'
    const value = parseValue(valueS || '')
    const values = valuesS.split(',').map(v => parseValue(v.trim())).filter(isNotUndefined)
    return value ? {op, value, values} : cond
}

export function parseValue(value: string): ParsedSqlValue | undefined {
    let res: RegExpMatchArray | null
    if (res = value.match(/^(\d+)$/)) {
        return parseInt(res[1])
    } else if (res = value.match(/^'([^']+)'$/)) {
        return res[1]
    } else if (res = value.match(/^(?:(.+?)\.)?([a-zA-Z0-9_$#]+?|["`].+?["`])$/i)) {
        return removeUndefined({column: removeQuotes(res[2]), scope: res[1] ? removeQuotes(res[1]) : undefined})
    }
    return undefined
}
