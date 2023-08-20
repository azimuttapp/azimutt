import {
    ColumnName,
    columnPathSeparator,
    ColumnPathStr,
    SchemaName,
    SqlFragment,
    TableName
} from "@azimutt/database-types";

export function buildSqlTable(schema: SchemaName, table: TableName): SqlFragment {
    const sqlSchema = schema ? `"${schema}".` : ''
    return `${sqlSchema}"${table}"`
}

export function buildSqlColumn(column: ColumnName | ColumnPathStr): SqlFragment {
    const [head, ...tail] = column.split(columnPathSeparator)
    return `"${head}"${tail.map(t => `->'${t}'`).join('')}`
}
