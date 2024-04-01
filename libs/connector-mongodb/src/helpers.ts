import {CatalogName, ConnectorScopeOpts, DatabaseName, EntityName, SchemaName} from "@azimutt/database-model";

export type ScopeValues = { database?: DatabaseName, catalog?: CatalogName, schema?: SchemaName, entity?: EntityName }

export function scopeFilter(values: ScopeValues, opts: ConnectorScopeOpts): boolean {
    const databaseFilter = values.database && opts.database ? scopeMatch(values.database, opts.database) : values.database !== 'local'
    const catalogFilter = values.catalog && opts.catalog ? scopeMatch(values.catalog, opts.catalog) : true
    const schemaFilter = values.schema && opts.schema ? scopeMatch(values.schema, opts.schema) : true
    const entityFilter = values.entity && opts.entity ? scopeMatch(values.entity, opts.entity) : true
    return databaseFilter && catalogFilter && schemaFilter && entityFilter
}

function scopeMatch(value: string, opt: string): boolean {
    return opt.includes('%') ? new RegExp(opt.replaceAll('%', '.*')).test(value) : value === opt
}
