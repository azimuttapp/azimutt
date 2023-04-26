// MUST stay sync with ./desktop/src/shared.ts

export type ElectronBridge = {
    versions: {
        node: () => string
        chrome: () => string
        electron: () => string
    }
    ping: () => Promise<string>
    getDatabaseSchema: (url: DatabaseUrl) => Promise<DatabaseSchema>
    getTableStats: (url: DatabaseUrl, table: TableId) => Promise<TableStats>
    getColumnStats: (url: DatabaseUrl, column: ColumnRef) => Promise<ColumnStats>
    execQuery: (url: DatabaseUrl, query: string) => Promise<QueryResults>
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

export interface QueryResults {
    // TODO
    values: object[]
}
