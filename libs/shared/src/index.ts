import {
    AzimuttSchema,
    ColumnRef,
    ColumnStats,
    DatabaseQueryResults,
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
    getDatabaseSchema: (url: DatabaseUrl) => Promise<AzimuttSchema>
    getTableStats: (url: DatabaseUrl, table: TableId) => Promise<TableStats>
    getColumnStats: (url: DatabaseUrl, ref: ColumnRef) => Promise<ColumnStats>
    runDatabaseQuery: (url: DatabaseUrl, query: string) => Promise<DatabaseQueryResults>
}
