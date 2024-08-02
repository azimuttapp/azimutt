import {AttributePath, ConnectorScopeOpts, EntityRef, SqlFragment} from "@azimutt/models";

export function buildSqlTable(ref: EntityRef): SqlFragment {
    return (ref.schema ? quoted(ref.schema) + '.' : '') + quoted(ref.entity)
}

export function buildSqlColumn(path: AttributePath): SqlFragment {
    const [head, ...tail] = path
    return quoted(head) + (tail.length > 0 ? `->>'$.${tail.join('.')}'` : '')
}

const quoted = (name: string): string => '`' + name + '`'

export type ScopeFields = { database?: SqlFragment, catalog?: SqlFragment, schema?: SqlFragment, entity?: SqlFragment }

export function scopeWhere(fields: ScopeFields, opts: ConnectorScopeOpts): SqlFragment {
    const databaseFilter = fields.database && opts.database ? `${fields.database} ${scopeOp(opts.database)} '${opts.database}'` : ''
    const catalogFilter = fields.catalog && opts.catalog ? `${fields.catalog} ${scopeOp(opts.catalog)} '${opts.catalog}'` : ''
    const schemaFilter = fields.schema && opts.schema ? `${fields.schema} ${scopeOp(opts.schema)} '${opts.schema}'` : `${fields.schema} NOT IN ('information_schema', 'performance_schema')`
    const entityFilter = fields.entity && opts.entity ? `${fields.entity} ${scopeOp(opts.entity)} '${opts.entity}'` : ''
    return [databaseFilter, catalogFilter, schemaFilter, entityFilter].filter(f => !!f).join(' AND ')
}

function scopeOp(scope: string): SqlFragment {
    return scope.includes('%') ? 'LIKE' : '='
}
