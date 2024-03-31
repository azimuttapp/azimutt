import {
    AttributePath,
    CatalogName,
    DatabaseName,
    EntityName,
    EntityRef,
    SchemaName,
    SqlFragment
} from "@azimutt/database-model";

export function buildSqlTable(ref: EntityRef): SqlFragment {
    // TODO: escape tables with special names (keywords or non-standard)
    return `${ref.schema ? `${ref.schema}.` : ''}${ref.entity}`
}

export function buildSqlColumn(path: AttributePath): SqlFragment {
    return path.join('.') // FIXME: handle nested columns (JSON)
}

export type ScopeOpts = { database?: DatabaseName, catalog?: CatalogName, schema?: SchemaName, entity?: EntityName }
export type ScopeFields = { database?: SqlFragment, catalog?: SqlFragment, schema?: SqlFragment, entity?: SqlFragment }

export function scopeWhere(fields: ScopeFields, opts: ScopeOpts): SqlFragment {
    const databaseFilter = fields.database && opts.database ? `${fields.database} ${scopeOp(opts.database)} '${opts.database}'` : ''
    const catalogFilter = fields.catalog && opts.catalog ? `${fields.catalog} ${scopeOp(opts.catalog)} '${opts.catalog}'` : ''
    const schemaFilter = fields.schema && opts.schema ? `${fields.schema} ${scopeOp(opts.schema)} '${opts.schema}'` : `${fields.schema} NOT IN ('information_schema', 'performance_schema', 'sys', 'sky', 'mysql')`
    const entityFilter = fields.entity && opts.entity ? `${fields.entity} ${scopeOp(opts.entity)} '${opts.entity}'` : ''
    return [databaseFilter, catalogFilter, schemaFilter, entityFilter].filter(f => !!f).join(' AND ')
}

function scopeOp(scope: string): SqlFragment {
    return scope.includes('%') ? 'LIKE' : '='
}
