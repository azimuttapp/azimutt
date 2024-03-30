import {
    AttributePath,
    ConnectorSchemaOpts,
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

export function scopeFilter(schemaField: string, schemaScope: SchemaName | undefined, entityField?: string, entityScope?: EntityName): SqlFragment {
    const schemaFilter = schemaScope ? `${schemaField} ${scopeOp(schemaScope)} '${schemaScope}'` : `${schemaField} NOT IN ('information_schema', 'sys')`
    const entityFilter = entityField && entityScope ? ` AND ${entityField} ${scopeOp(entityScope)} '${entityScope}'` : ''
    return schemaFilter + entityFilter
}

function scopeOp(scope: string): SqlFragment {
    return scope.includes('%') ? 'LIKE' : '='
}
