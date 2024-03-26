import {AttributePath, EntityRef, SchemaName, SqlFragment} from "@azimutt/database-model";

export function buildSqlTable(ref: EntityRef): SqlFragment {
    // TODO: escape tables with special names (keywords or non-standard)
    return `${ref.schema ? `${ref.schema}.` : ''}${ref.entity}`
}

export function buildSqlColumn(path: AttributePath): SqlFragment {
    return path.join('.') // FIXME: handle nested columns (JSON)
}

export function buildColumnType(schema?: SchemaName): string {
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
