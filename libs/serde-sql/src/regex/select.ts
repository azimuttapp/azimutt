import {removeUndefined} from "@azimutt/utils";

export type SelectCommand = { command: 'SELECT', fields: SelectField[], tables: SelectTable[], where?: string, groupBy?: string, having?: string, sort?: string, limit?: number, offset?: number }
export type SelectField = { name: string, expression?: string, scope?: string }
export type SelectTable = { name: string, alias?: string, on?: string }

export function parseSelect(sql: string): SelectCommand {
    const res = sql.trim().match(/^SELECT\s+(.+?)\s+FROM\s+(.+?)((?:\s+(?:FULL\s+)?(?:LEFT\s+)?(?:RIGHT\s+)?(?:INNER\s+)?(?:OUTER\s+)?JOIN\s+.+?)+)?(?:\s+WHERE\s+(.+?))?(?:\s+GROUP BY\s+(.+?))?(?:\s+HAVING\s+(.+?))?(?:\s+ORDER BY\s+(.+?))?(?:\s+LIMIT\s+(\d+?))?(?:\s+OFFSET\s+(\d+?))?;?$/i) || []
    const [, fieldsStr, tableStr, joinsStr, whereStr, groupByStr, havingStr, orderByStr, limitStr, offsetStr] = res
    const fields = fieldsStr.split(',').map(parseSelectField)
    const joins = (joinsStr || '').split(/(?:FULL\s+)?(?:LEFT\s+)?(?:RIGHT\s+)?(?:INNER\s+)?(?:OUTER\s+)?JOIN/i).slice(1).map(parseSelectJoin)
    const command: SelectCommand = {
        command: 'SELECT',
        fields,
        tables: [parseSelectTable(tableStr), ...joins],
        where: whereStr,
        groupBy: groupByStr,
        having: havingStr,
        sort: orderByStr,
        limit: limitStr ? parseInt(limitStr) : undefined,
        offset: offsetStr ? parseInt(offsetStr) : undefined
    }
    return removeUndefined(command)
}

export function parseSelectField(sql: string): SelectField {
    const [, scope, name, alias] = sql.trim().match(/^(?:(\S+)\.)?(\S+?.*?\S*?)(?:\s+AS\s+(\S+))?$/i) || []
    return removeUndefined(alias ? {name: alias, expression: name, scope} : {name, scope})
}

export function parseSelectTable(sql: string): SelectTable {
    const res = sql.trim().match(/^(\S+)(?:\s+(\S+))?$/i) || []
    const [, name, alias] = res
    return alias ? {name: alias, alias: name} : {name}
}

export function parseSelectJoin(sql: string): SelectTable {
    const res = sql.trim().match(/^(\S+)(?:\s+(\S+))?(?:\s+ON\s+(.+)\s*)?$/i) || []
    const [, name, alias, on] = res
    return alias ? {name: alias, alias: name, on} : {name, on}
}
