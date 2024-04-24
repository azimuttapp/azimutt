import {
    AttributePath,
    CatalogName,
    ConnectorScopeOpts,
    DatabaseName,
    EntityName,
    EntityRef,
    SchemaName,
    SqlFragment
} from "@azimutt/models";

export function buildSqlTable(ref: EntityRef): SqlFragment {
    const sqlSchema = ref.schema ? `"${ref.schema}".` : ''
    return `${sqlSchema}"${ref.entity}"`
}

export function buildSqlColumn(path: AttributePath): SqlFragment {
    const [head, ...tail] = path
    return `"${head}"${tail.map(t => `->'${t}'`).join('')}`
}

export type ScopeFields = { database?: SqlFragment, catalog?: SqlFragment, schema?: SqlFragment, entity?: SqlFragment }
export type ScopeValues = { database?: DatabaseName, catalog?: CatalogName, schema?: SchemaName, entity?: EntityName }

export function scopeWhere(fields: ScopeFields, opts: ConnectorScopeOpts): SqlFragment {
    const databaseFilter = fields.database && opts.database ? `${fields.database} ${scopeOp(opts.database)} '${opts.database}'` : ''
    const catalogFilter = fields.catalog && opts.catalog ? `${fields.catalog} ${scopeOp(opts.catalog)} '${opts.catalog}'` : ''
    const schemaFilter = fields.schema && opts.schema ? `${fields.schema} ${scopeOp(opts.schema)} '${opts.schema}'` : `${fields.schema} != 'INFORMATION_SCHEMA'`
    const entityFilter = fields.entity && opts.entity ? `${fields.entity} ${scopeOp(opts.entity)} '${opts.entity}'` : ''
    return [databaseFilter, catalogFilter, schemaFilter, entityFilter].filter(f => !!f).join(' AND ')
}

function scopeOp(scope: string): SqlFragment {
    return scope.includes('%') ? 'LIKE' : '='
}

export function scopeFilter(values: ScopeValues, opts: ConnectorScopeOpts): boolean {
    const databaseFilter = values.database && opts.database ? scopeMatch(values.database, opts.database) : true
    const catalogFilter = values.catalog && opts.catalog ? scopeMatch(values.catalog, opts.catalog) : true
    const schemaFilter = values.schema && opts.schema ? scopeMatch(values.schema, opts.schema) : values.schema !== 'INFORMATION_SCHEMA'
    const entityFilter = values.entity && opts.entity ? scopeMatch(values.entity, opts.entity) : true
    return databaseFilter && catalogFilter && schemaFilter && entityFilter
}

function scopeMatch(value: string, opt: string): boolean {
    return opt.includes('%') ? new RegExp(opt.replaceAll('%', '.*')).test(value) : value === opt
}
