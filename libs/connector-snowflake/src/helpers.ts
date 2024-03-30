import {
    AttributePath,
    CatalogName,
    ConnectorSchemaOpts,
    EntityName,
    EntityRef,
    SchemaName,
    SqlFragment
} from "@azimutt/database-model";

export function buildSqlTable(ref: EntityRef): SqlFragment {
    const sqlSchema = ref.schema ? `"${ref.schema}".` : ''
    return `${sqlSchema}"${ref.entity}"`
}

export function buildSqlColumn(path: AttributePath): SqlFragment {
    const [head, ...tail] = path
    return `"${head}"${tail.map(t => `->'${t}'`).join('')}`
}

export function handleError<T>(msg: string, onError: T, {logger, ignoreErrors}: ConnectorSchemaOpts) {
    return (err: any): Promise<T> => {
        if (ignoreErrors) {
            logger.warn(`${msg}. Ignoring...`)
            return Promise.resolve(onError)
        } else {
            return Promise.reject(err)
        }
    }
}

export function scopeFilter(catalogField: string, catalogScope: CatalogName | undefined, schemaField: string, schemaScope: SchemaName | undefined, entityField?: string, entityScope?: EntityName): SqlFragment {
    const catalogFilter = catalogScope ? `${catalogField} ${scopeOp(catalogScope)} '${catalogScope}' AND ` : ''
    const schemaFilter = schemaScope ? `${schemaField} ${scopeOp(schemaScope)} '${schemaScope}'` : `${schemaField} != 'INFORMATION_SCHEMA'`
    const entityFilter = entityField && entityScope ? ` AND ${entityField} ${scopeOp(entityScope)} '${entityScope}'` : ''
    return catalogFilter + schemaFilter + entityFilter
}

function scopeOp(scope: string): SqlFragment {
    return scope.includes('%') ? 'LIKE' : '='
}

export function scopeMatch(value: string, scope: string): boolean {
    return scope.includes('%') ? new RegExp(scope.replaceAll('%', '.*')).test(value) : value === scope
}
