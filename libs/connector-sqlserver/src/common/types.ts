import {AttributeValue} from "@azimutt/database-model";

export type QueryResultValue = AttributeValue
export type QueryResultRow = { [column: string]: QueryResultValue }
export type QueryResultField = { name: string }
export type QueryResultRowArray = QueryResultValue[]
export type QueryResultArrayMode = {
    fields: QueryResultField[],
    rows: QueryResultRowArray[]
}

export interface Conn {
    query<T extends QueryResultRow>(sql: string, parameters?: any[], name?: string): Promise<T[]>

    queryArrayMode(sql: string, parameters?: any[], name?: string): Promise<QueryResultArrayMode>
}
