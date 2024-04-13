import {AttributePath, ConnectorScopeOpts, EntityRef, SchemaName, SqlFragment} from "@azimutt/models";

export function buildSqlTable(ref: EntityRef): SqlFragment {
    // TODO: escape tables with special names (keywords or non-standard)
    return `${ref.schema ? `${ref.schema}.` : ''}${ref.entity}`
}

export function buildSqlColumn(path: AttributePath): SqlFragment {
    return path.join('.') // FIXME: handle nested columns (JSON)
}

export function buildColumnType(schema?: SchemaName): SqlFragment {
    const prefix = schema ? `${schema}.` : ''
    return `${prefix}DATA_TYPE
               + CASE
                     WHEN ${prefix}DATA_TYPE IN ('char', 'nchar', 'varchar', 'nvarchar', 'binary', 'varbinary')
                         AND ${prefix}CHARACTER_MAXIMUM_LENGTH > 0 THEN
                         COALESCE('(' + CONVERT(varchar, ${prefix}CHARACTER_MAXIMUM_LENGTH) + ')', '')
                     ELSE '' END
               + CASE
                     WHEN DATA_TYPE IN ('decimal', 'numeric') THEN
                         COALESCE('(' + CONVERT(varchar, ${prefix}NUMERIC_PRECISION) + ',' +
                                  CONVERT(varchar, ${prefix}NUMERIC_SCALE) +
                                  ')', '')
                     ELSE '' END`
}

export type ScopeFields = { database?: SqlFragment, catalog?: SqlFragment, schema?: SqlFragment, entity?: SqlFragment }

export function scopeWhere(fields: ScopeFields, opts: ConnectorScopeOpts): SqlFragment {
    const databaseFilter = fields.database && opts.database ? `${fields.database} ${scopeOp(opts.database)} '${opts.database}'` : ''
    const catalogFilter = fields.catalog && opts.catalog ? `${fields.catalog} ${scopeOp(opts.catalog)} '${opts.catalog}'` : ''
    const schemaFilter = fields.schema && opts.schema ? `${fields.schema} ${scopeOp(opts.schema)} '${opts.schema}'` : `${fields.schema} NOT IN ('information_schema', 'sys')`
    const entityFilter = fields.entity && opts.entity ? `${fields.entity} ${scopeOp(opts.entity)} '${opts.entity}'` : ''
    return [databaseFilter, catalogFilter, schemaFilter, entityFilter].filter(f => !!f).join(' AND ')
}

function scopeOp(scope: string): SqlFragment {
    return scope.includes('%') ? 'LIKE' : '='
}
