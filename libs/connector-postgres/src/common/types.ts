import {ColumnValue} from "@azimutt/database-types";

export type QueryResultValue = ColumnValue
export type QueryResultRow = { [column: string]: QueryResultValue }
export type QueryResultField = { name: string, tableID: number, columnID: number, dataTypeID: number, format: string }
export type QueryResultRowArray = QueryResultValue[]
export type QueryResultArrayMode = {
    fields: QueryResultField[],
    rows: QueryResultRowArray[]
}

export interface Conn {
    query<T extends QueryResultRow>(sql: string, parameters?: any[]): Promise<T[]>

    queryArrayMode(sql: string, parameters?: any[]): Promise<QueryResultArrayMode>
}
