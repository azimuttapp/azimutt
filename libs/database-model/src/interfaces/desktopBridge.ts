import {ConnectorAttributeStats, ConnectorEntityStats, DatabaseQuery, QueryAnalyze, QueryResults} from "./connector";
import {DatabaseUrlParsed} from "../databaseUrl";
import {AttributeRef, Database, EntityRef} from "../database";

export type DesktopBridge = {
    versions: {
        node: () => string
        chrome: () => string
        electron: () => string
    }
    ping: () => Promise<string>
    // like Connector but a bit different ^^ (no application parameter)
    getSchema(url: DatabaseUrlParsed): Promise<Database>
    getQueryHistory(url: DatabaseUrlParsed): Promise<DatabaseQuery[]>
    execute(url: DatabaseUrlParsed, query: string, parameters: any[]): Promise<QueryResults>
    analyze(url: DatabaseUrlParsed, query: string, parameters: any[]): Promise<QueryAnalyze>
    getEntityStats(url: DatabaseUrlParsed, ref: EntityRef): Promise<ConnectorEntityStats>
    getAttributeStats(url: DatabaseUrlParsed, ref: AttributeRef): Promise<ConnectorAttributeStats>
}
