import {
    ColumnRef,
    ColumnStats,
    DatabaseResults,
    DatabaseSchema,
    DatabaseUrl,
    TableId,
    TableStats
} from "@azimutt/database-types";

export type DesktopBridge = {
    versions: {
        node: () => string
        chrome: () => string
        electron: () => string
    }
    ping: () => Promise<string>
    databaseQuery: (url: DatabaseUrl, query: string) => Promise<DatabaseResults>
    databaseSchema: (url: DatabaseUrl) => Promise<DatabaseSchema>
    tableStats: (url: DatabaseUrl, table: TableId) => Promise<TableStats>
    columnStats: (url: DatabaseUrl, column: ColumnRef) => Promise<ColumnStats>
}
