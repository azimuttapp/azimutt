import {SchemaName} from "@azimutt/database-types";

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
