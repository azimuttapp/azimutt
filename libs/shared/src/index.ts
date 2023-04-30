import {
    AzimuttSchema,
    ColumnRef,
    ColumnStats,
    DatabaseResults,
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
    queryDatabase: (url: DatabaseUrl, query: string) => Promise<DatabaseResults>
    getDatabaseSchema: (url: DatabaseUrl) => Promise<AzimuttSchema>
    getTableStats: (url: DatabaseUrl, table: TableId) => Promise<TableStats>
    getColumnStats: (url: DatabaseUrl, ref: ColumnRef) => Promise<ColumnStats>
}
