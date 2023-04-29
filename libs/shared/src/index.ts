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
    databaseQuery: (url: DatabaseUrl, query: string) => Promise<DatabaseResults>
    databaseSchema: (url: DatabaseUrl) => Promise<AzimuttSchema>
    tableStats: (url: DatabaseUrl, table: TableId) => Promise<TableStats>
    columnStats: (url: DatabaseUrl, ref: ColumnRef) => Promise<ColumnStats>
}
