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
export type ParsedSelectColumn = {name: string, scope?: string, def?: string}
export type ParsedSelectJoin = {table: string, schema?: string, alias?: string, kind?: 'INNER' | 'LEFT' | 'RIGHT' | 'FULL', on?: ParsedSqlCondition}
export type ParsedSelectWhere = {}
export type ParsedSelectGroupBy = {}
export type ParsedSelectHaving = {}
export type ParsedSelectOrderBy = {}
export type ParsedSelectOffset = {}
export type ParsedSelectLimit = {}
export type ParsedSqlCondition = ParsedSqlConditionBool | ParsedSqlConditionExp | ParsedSqlConditionNull | ParsedSqlConditionIn | string
export type ParsedSqlConditionBool = { op: 'AND' | 'OR', left: ParsedSqlCondition, right: ParsedSqlCondition }
export type ParsedSqlConditionExp = { op: '=' | '!=' | '>' | '>=' | '<' | '<=' | '<>', left: ParsedSqlValue, right: ParsedSqlValue }
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

export function parseSelectStatement(select: string): ParsedSelectStatement | undefined {
    const [, columns, tables, where, groupBy, having, orderBy, limit, offset, fetch] = select.trim().match(/^SELECT\s+(.+?)\s+FROM\s+(.+?)(?:\s+WHERE\s+(.+?))?(?:\s+GROUP\s+BY\s+(.+?))?(?:\s+HAVING\s+(.+?))?(?:\s+ORDER\s+BY\s+(.+?))?(?:\s+LIMIT\s+(.+?))?(?:\s+OFFSET\s+(.+?))?(?:\s+FETCH\s+(.+?))?\s*;$/i) || []
    const parsedColumns: ParsedSelectColumn[] = (columns || '').split(',').map((c, i) => parseSelectColumn(c.trim(), i + 1)).filter(c => !!c)
    const parsedTable: { table: ParsedSelectTable; joins?: ParsedSelectJoin[] } | undefined = parseSelectTable(tables || '')
    if (parsedTable && parsedColumns.length > 0) {
        return removeEmpty({command: 'SELECT' as const, table: parsedTable.table, columns: parsedColumns, joins: parsedTable.joins})
    } else {
        return undefined
    }
}

export function parseSelectColumn(column: string, index: number): ParsedSelectColumn | undefined {
    const [, scope, def, alias] = (column.match(/^(?:(.+?)\.)?(.+?)(?:\s+AS\s+(.+?))?$/i) || []).map(r => r ? removeQuotes(r) : undefined)
    if (alias) {
        return removeUndefined({name: alias, scope, def})
    } else if (def === '*' || def?.match(/^["]?[a-z]+["]?$/i)) { // simple column
        return removeUndefined({name: def, scope})
    } else { // expression
        return removeUndefined({name: `col_${index}`, scope, def})
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
    } else if (cond.search(/[=<>]/) !== -1) {
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
    const [, leftS, opS, rightS] = cond.match(/^(.+?)\s*(=|!=|>|>=|<|<=|<>)\s*(.+?)$/) || []
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
