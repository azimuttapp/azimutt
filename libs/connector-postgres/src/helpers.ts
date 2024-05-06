import {AttributePath, ConnectorScopeOpts, EntityRef, SqlFragment} from "@azimutt/models";

export function buildSqlTable(ref: EntityRef): SqlFragment {
    const sqlSchema = ref.schema ? `"${ref.schema}".` : ''
    return `${sqlSchema}"${ref.entity}"`
}

export function buildSqlColumn(path: AttributePath): SqlFragment {
    const [head, ...tail] = path
    return `"${head}"${tail.map(t => `->'${t}'`).join('')}`
}

export type ScopeFields = { database?: SqlFragment, catalog?: SqlFragment, schema?: SqlFragment, entity?: SqlFragment }

export function scopeWhere(fields: ScopeFields, opts: ConnectorScopeOpts): SqlFragment {
    const databaseFilter = fields.database && opts.database ? `${fields.database} ${scopeOp(opts.database)} '${scopeValue(opts.database)}'` : ''
    const catalogFilter = fields.catalog && opts.catalog ? `${fields.catalog} ${scopeOp(opts.catalog)} '${scopeValue(opts.catalog)}'` : ''
    const schemaFilter = fields.schema && opts.schema ? `${fields.schema} ${scopeOp(opts.schema)} '${scopeValue(opts.schema)}'` : fields.schema ? `${fields.schema} NOT IN ('information_schema', 'pg_catalog')` : ''
    const entityFilter = fields.entity && opts.entity ? `${fields.entity} ${scopeOp(opts.entity)} '${scopeValue(opts.entity)}'` : ''
    return [databaseFilter, catalogFilter, schemaFilter, entityFilter].filter(f => !!f).join(' AND ')
}

function scopeOp(scope: string): SqlFragment {
    if (scope.startsWith('!')) {
        return scope.includes('%') ? 'NOT LIKE' : '!='
    } else {
        return scope.includes('%') ? 'LIKE' : '='
    }
}

function scopeValue(scope: string): SqlFragment {
    return scope.startsWith('!') ? scope.slice(1) : scope
}

// sadly pg_catalog schema doesn't have relations, so let's define them here for easy exploration
export const pgCatalogRelations = [
    {src: {table: 'pg_attrdef', column: 'adrelid'}, ref: {table: 'pg_class', column: 'oid'}},
    {src: {table: 'pg_attrdef', column: 'adnum'}, ref: {table: 'pg_attribute', column: 'attnum'}},
    {src: {table: 'pg_attribute', column: 'attrelid'}, ref: {table: 'pg_class', column: 'oid'}},
    {src: {table: 'pg_attribute', column: 'atttypid'}, ref: {table: 'pg_type', column: 'oid'}},
    {src: {table: 'pg_attribute', column: 'attcollation'}, ref: {table: 'pg_collation', column: 'oid'}},
    {src: {table: 'pg_class', column: 'relnamespace'}, ref: {table: 'pg_namespace', column: 'oid'}},
    {src: {table: 'pg_class', column: 'reltype'}, ref: {table: 'pg_type', column: 'oid'}},
    {src: {table: 'pg_class', column: 'reloftype'}, ref: {table: 'pg_type', column: 'oid'}},
    {src: {table: 'pg_class', column: 'relowner'}, ref: {table: 'pg_authid', column: 'oid'}},
    {src: {table: 'pg_class', column: 'relam'}, ref: {table: 'pg_am', column: 'oid'}},
    {src: {table: 'pg_class', column: 'reltablespace'}, ref: {table: 'pg_tablespace', column: 'oid'}},
    {src: {table: 'pg_class', column: 'reltoastrelid'}, ref: {table: 'pg_class', column: 'oid'}},
    {src: {table: 'pg_class', column: 'relrewrite'}, ref: {table: 'pg_class', column: 'oid'}},
    {src: {table: 'pg_constraint', column: 'connamespace'}, ref: {table: 'pg_namespace', column: 'oid'}},
    {src: {table: 'pg_constraint', column: 'conrelid'}, ref: {table: 'pg_class', column: 'oid'}},
    {src: {table: 'pg_constraint', column: 'contypid'}, ref: {table: 'pg_type', column: 'oid'}},
    {src: {table: 'pg_constraint', column: 'conindid'}, ref: {table: 'pg_class', column: 'oid'}},
    {src: {table: 'pg_constraint', column: 'conparentid'}, ref: {table: 'pg_constraint', column: 'oid'}},
    {src: {table: 'pg_constraint', column: 'confrelid'}, ref: {table: 'pg_class', column: 'oid'}},
    {src: {table: 'pg_constraint', column: 'conkey'}, ref: {table: 'pg_attribute', column: 'attnum'}},
    {src: {table: 'pg_constraint', column: 'confkey'}, ref: {table: 'pg_attribute', column: 'attnum'}},
    {src: {table: 'pg_constraint', column: 'conpfeqop'}, ref: {table: 'pg_operator', column: 'oid'}},
    {src: {table: 'pg_constraint', column: 'conppeqop'}, ref: {table: 'pg_operator', column: 'oid'}},
    {src: {table: 'pg_constraint', column: 'conffeqop'}, ref: {table: 'pg_operator', column: 'oid'}},
    {src: {table: 'pg_constraint', column: 'confdelsetcols'}, ref: {table: 'pg_attribute', column: 'attnum'}},
    {src: {table: 'pg_constraint', column: 'conexclop'}, ref: {table: 'pg_operator', column: 'oid'}},
    {src: {table: 'pg_description', column: 'classoid'}, ref: {table: 'pg_class', column: 'oid'}},
    {src: {table: 'pg_index', column: 'indexrelid'}, ref: {table: 'pg_class', column: 'oid'}},
    {src: {table: 'pg_index', column: 'indrelid'}, ref: {table: 'pg_class', column: 'oid'}},
    {src: {table: 'pg_index', column: 'indkey'}, ref: {table: 'pg_attribute', column: 'attnum'}},
    {src: {table: 'pg_index', column: 'indcollation'}, ref: {table: 'pg_collation', column: 'oid'}},
    {src: {table: 'pg_index', column: 'indclass'}, ref: {table: 'pg_opclass', column: 'oid'}},
    {src: {table: 'pg_namespace', column: 'nspowner'}, ref: {table: 'pg_authid', column: 'oid'}},
    {src: {table: 'pg_stats', column: 'schemaname'}, ref: {table: 'pg_namespace', column: 'nspname'}},
    {src: {table: 'pg_stats', column: 'tablename'}, ref: {table: 'pg_class', column: 'relname'}},
    {src: {table: 'pg_stats', column: 'attname'}, ref: {table: 'pg_attribute', column: 'attname'}},
    {src: {table: 'pg_stat_all_indexes', column: 'relid'}, ref: {table: 'pg_class', column: 'oid'}},
    {src: {table: 'pg_stat_all_indexes', column: 'indexrelid'}, ref: {table: 'pg_index', column: 'oid'}},
    {src: {table: 'pg_stat_all_tables', column: 'relid'}, ref: {table: 'pg_class', column: 'oid'}},
    {src: {table: 'pg_statio_all_indexes', column: 'relid'}, ref: {table: 'pg_class', column: 'oid'}},
    {src: {table: 'pg_statio_all_indexes', column: 'indexrelid'}, ref: {table: 'pg_index', column: 'oid'}},
    {src: {table: 'pg_statio_all_tables', column: 'relid'}, ref: {table: 'pg_class', column: 'oid'}},
    {src: {table: 'pg_statistic', column: 'starelid'}, ref: {table: 'pg_class', column: 'oid'}},
    {src: {table: 'pg_statistic', column: 'staattnum'}, ref: {table: 'pg_attribute', column: 'attnum'}},
    {src: {table: 'pg_statistic', column: 'staopN'}, ref: {table: 'pg_operator', column: 'oid'}},
    {src: {table: 'pg_statistic', column: 'stacollN'}, ref: {table: 'pg_collation', column: 'oid'}},
    {src: {table: 'pg_type', column: 'typnamespace'}, ref: {table: 'pg_namespace', column: 'oid'}},
    {src: {table: 'pg_type', column: 'typowner'}, ref: {table: 'pg_authid', column: 'oid'}},
    {src: {table: 'pg_type', column: 'typrelid'}, ref: {table: 'pg_class', column: 'oid'}},
    {src: {table: 'pg_type', column: 'typsubscript'}, ref: {table: 'pg_proc', column: 'oid'}},
    {src: {table: 'pg_type', column: 'typelem'}, ref: {table: 'pg_type', column: 'oid'}},
    {src: {table: 'pg_type', column: 'typarray'}, ref: {table: 'pg_type', column: 'oid'}},
    {src: {table: 'pg_type', column: 'typinput'}, ref: {table: 'pg_proc', column: 'oid'}},
    {src: {table: 'pg_type', column: 'typoutput'}, ref: {table: 'pg_proc', column: 'oid'}},
    {src: {table: 'pg_type', column: 'typreceive'}, ref: {table: 'pg_proc', column: 'oid'}},
    {src: {table: 'pg_type', column: 'typsend'}, ref: {table: 'pg_proc', column: 'oid'}},
    {src: {table: 'pg_type', column: 'typmodin'}, ref: {table: 'pg_proc', column: 'oid'}},
    {src: {table: 'pg_type', column: 'typmodout'}, ref: {table: 'pg_proc', column: 'oid'}},
    {src: {table: 'pg_type', column: 'typanalyze'}, ref: {table: 'pg_proc', column: 'oid'}},
    {src: {table: 'pg_type', column: 'typbasetype'}, ref: {table: 'pg_type', column: 'oid'}},
    {src: {table: 'pg_type', column: 'typcollation'}, ref: {table: 'pg_collation', column: 'oid'}},
]
/*
Extract relations from pg doc (https://www.postgresql.org/docs/current/catalog-pg-constraint.html)
```js
const table = document.querySelector('p.title .structname').textContent
const columns = [...document.querySelector('table.table').querySelectorAll('tbody tr')].map(e => {
    const table = e.querySelector('.column_definition a.link .structname')?.textContent
    return {
        name: e.querySelector('.structfield').textContent,
        type: e.querySelector('.type').textContent,
        rel: table ? {table, column: e.querySelectorAll('.structfield')[1].textContent} : undefined
    }
})
const code = columns.filter(c => c.rel).map(c => {
    return `{src: {table: '${table}', column: '${c.name}'}, ref: {table: '${c.rel?.table}', column: '${c.rel?.column}'}},`
}).join('\n')
copy(code)
code
```
*/
