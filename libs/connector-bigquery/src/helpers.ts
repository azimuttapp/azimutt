import {
    CatalogName,
    ConnectorScopeOpts,
    DatabaseName,
    EntityName,
    SchemaName,
    SqlFragment
} from "@azimutt/models";

export type ScopeFields = { database?: SqlFragment, catalog?: SqlFragment, schema?: SqlFragment, entity?: SqlFragment }
export type ScopeValues = { database?: DatabaseName, catalog?: CatalogName, schema?: SchemaName, entity?: EntityName }

export function scopeWhere(prefix: string, fields: ScopeFields, opts: ConnectorScopeOpts): SqlFragment {
    const databaseFilter = fields.database && opts.database ? `${fields.database} ${scopeOp(opts.database)} '${opts.database}'` : ''
    const catalogFilter = fields.catalog && opts.catalog ? `${fields.catalog} ${scopeOp(opts.catalog)} '${opts.catalog}'` : ''
    const schemaFilter = fields.schema && opts.schema ? `${fields.schema} ${scopeOp(opts.schema)} '${opts.schema}'` : ''
    const entityFilter = fields.entity && opts.entity ? `${fields.entity} ${scopeOp(opts.entity)} '${opts.entity}'` : ''
    const filter = [databaseFilter, catalogFilter, schemaFilter, entityFilter].filter(f => !!f).join(' AND ')
    return filter ? prefix + filter : ''
}

function scopeOp(scope: string): SqlFragment {
    return scope.includes('%') ? 'LIKE' : '='
}

export function scopeFilter(values: ScopeValues, opts: ConnectorScopeOpts): boolean {
    const databaseFilter = values.database && opts.database ? scopeMatch(values.database, opts.database) : true
    const catalogFilter = values.catalog && opts.catalog ? scopeMatch(values.catalog, opts.catalog) : true
    const schemaFilter = values.schema && opts.schema ? scopeMatch(values.schema, opts.schema) : true
    const entityFilter = values.entity && opts.entity ? scopeMatch(values.entity, opts.entity) : true
    return databaseFilter && catalogFilter && schemaFilter && entityFilter
}

function scopeMatch(value: string, opt: string): boolean {
    return opt.includes('%') ? new RegExp(opt.replaceAll('%', '.*')).test(value) : value === opt
}

export function removeQuotes(value: string): string {
    if (value.startsWith('"') && value.endsWith('"')) return value.slice(1, -1)
    if (value.startsWith("'") && value.endsWith("'")) return value.slice(1, -1)
    return value
}
