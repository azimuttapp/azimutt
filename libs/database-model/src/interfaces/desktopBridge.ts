import {ConnectorAttributeStats, ConnectorEntityStats, DatabaseQuery, QueryAnalyze, QueryResults} from "./connector";
import {DatabaseUrl} from "../databaseUrl";
import {AttributeRef, Database, EntityRef} from "../database";

export type DesktopBridge = {
    versions: {
        node: () => string
        chrome: () => string
        electron: () => string
    }
    ping: () => Promise<string>
    // like Connector but a bit different ^^ (no application parameter)
    getSchema(url: DatabaseUrl): Promise<Database>
    getQueryHistory(url: DatabaseUrl): Promise<DatabaseQuery[]>
    execute(url: DatabaseUrl, query: string, parameters: any[]): Promise<QueryResults>
    analyze(url: DatabaseUrl, query: string, parameters: any[]): Promise<QueryAnalyze>
    getEntityStats(url: DatabaseUrl, ref: EntityRef): Promise<ConnectorEntityStats>
    getAttributeStats(url: DatabaseUrl, ref: AttributeRef): Promise<ConnectorAttributeStats>
}
