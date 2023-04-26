// MUST stay sync with ./frontend/ts-src/types/desktop.ts

export type DesktopBridge = {
    versions: {
        node: () => string
        chrome: () => string
        electron: () => string
    }
    ping: () => Promise<string>
    databaseQuery: (url: DatabaseUrl, query: string) => Promise<QueryResults>
    databaseSchema: (url: DatabaseUrl) => Promise<DatabaseSchema>
    tableStats: (url: DatabaseUrl, table: TableId) => Promise<TableStats>
    columnStats: (url: DatabaseUrl, column: ColumnRef) => Promise<ColumnStats>
}

export interface QueryResults {
    rows: object[]
}

export type DatabaseUrl = string
export type TableId = string
export type SchemaName = string
export type TableName = string
export type ColumnName = string
export type ColumnRef = { table: TableId, column: ColumnName }
export type ColumnValue = string | number | boolean | null | unknown

export interface DatabaseSchema {
    // TODO
}

export interface TableStats {
    schema: SchemaName | null
    table: TableName
    rows: number
    sample_values: {[column: string]: ColumnValue}
}

export interface ColumnStats {
    schema: SchemaName | null
    table: TableName
    column: ColumnName
    rows: number
    nulls: number
    cardinality: number
    common_values: {value: ColumnValue, count: number}[]
}
