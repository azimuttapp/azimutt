import {AttributePath, ConnectorScopeOpts, EntityRef, SqlFragment} from "@azimutt/models";

export function buildSqlTable(ref: EntityRef): SqlFragment {
    return (ref.schema ? quoted(ref.schema) + '.' : '') + quoted(ref.entity)
}

export function buildSqlColumn(path: AttributePath): SqlFragment {
    const [head, ...tail] = path
    if (tail.length > 0) {
        return `JSON_VALUE(${quoted(head)}, '$.${tail.join('.')}')`
    } else {
        return quoted(head)
    }
}

const quoted = (name: string): string => '`' + name + '`'

export type ScopeFields = { database?: SqlFragment, catalog?: SqlFragment, schema?: SqlFragment, entity?: SqlFragment }

export function scopeWhere(fields: ScopeFields, opts: ConnectorScopeOpts): SqlFragment {
    const databaseFilter = fields.database && opts.database ? `${fields.database} ${scopeOp(opts.database)} '${scopeValue(opts.database)}'` : ''
    const catalogFilter = fields.catalog && opts.catalog ? `${fields.catalog} ${scopeOp(opts.catalog)} '${scopeValue(opts.catalog)}'` : ''
    const schemaFilter = fields.schema && opts.schema ? `${fields.schema} ${scopeOp(opts.schema)} '${scopeValue(opts.schema)}'` : fields.schema ? `${fields.schema} NOT IN ('information_schema', 'performance_schema', 'sys', 'sky', 'mysql')` : ''
    const entityFilter = fields.entity && opts.entity ? `${fields.entity} ${scopeOp(opts.entity)} '${scopeValue(opts.entity)}'` : ''
    return [databaseFilter, catalogFilter, schemaFilter, entityFilter].filter(f => !!f).join(' AND ')
}

export function scopeOp(scope: string): SqlFragment {
    if (scope.startsWith('!')) {
        return scope.includes('%') ? 'NOT LIKE' : '!='
    } else {
        return scope.includes('%') ? 'LIKE' : '='
    }
}

export function scopeValue(scope: string): SqlFragment {
    return scope.startsWith('!') ? scope.slice(1) : scope
}
