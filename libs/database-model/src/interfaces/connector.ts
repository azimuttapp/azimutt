import {Logger} from "@azimutt/utils";
import {DatabaseUrlParsed} from "../databaseUrl"
import {
    CatalogName,
    ColumnRef,
    ColumnType,
    ColumnValue,
    Database,
    DatabaseName,
    JsValue,
    SchemaName,
    EntityRef
} from "../database";

// every connector should implement this interface
export interface Connector {
    name: string
    getDatabase(application: string, url: DatabaseUrlParsed, opts: ConnectorSchemaOpts): Promise<Database>
    getEntityStats(application: string, url: DatabaseUrlParsed, entity: EntityRef): Promise<ConnectorEntityStats>
    getColumnStats(application: string, url: DatabaseUrlParsed, column: ColumnRef): Promise<ConnectorColumnStats>
    query(application: string, url: DatabaseUrlParsed, query: string, parameters: any[]): Promise<ConnectorQueryResults>
}

export type ConnectorSchemaOpts = {
    logger: Logger
    database?: DatabaseName // export only this database
    catalog?: CatalogName // export only this catalog
    schema?: SchemaName // export only this schema
    mixedCollection?: string // type attribute if collections have mixed documents
    sampleSize?: number // default: 100, number of documents used to infer the schema (document databases, json columns in relational db...)
    inferRelations?: boolean // default: false, infer relations based on column names
    ignoreErrors?: boolean // default: false, ignore errors when fetching the schema
}

export type ConnectorEntityStats = EntityRef & {
    rows: number
    sample_values: { [column: string]: ColumnValue }
}

export type ConnectorColumnStats = ColumnRef & {
    type: ColumnType
    rows: number
    nulls: number
    cardinality: number
    common_values: { value: ColumnValue, count: number }[]
}

export type ConnectorQueryResults = {
    query: string
    columns: { name: string, ref?: ColumnRef }[]
    rows: JsValue[]
}
