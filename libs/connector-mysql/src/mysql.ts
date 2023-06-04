import {Logger} from "@azimutt/utils";
import {AzimuttSchema, DatabaseUrlParsed} from "@azimutt/database-types";
import {ValueSchema} from "@azimutt/json-infer-schema";

export type MysqlSchema = { tables: MysqlTable[], relations: MysqlRelation[], types: MysqlType[] }
export type MysqlTable = { schema: MysqlSchemaName, table: MysqlTableName, view: boolean, columns: MysqlColumn[], primaryKey: MysqlPrimaryKey | null, uniques: MysqlUnique[], indexes: MysqlIndex[], checks: MysqlCheck[], comment: string | null }
export type MysqlColumn = { name: MysqlColumnName, type: MysqlColumnType, nullable: boolean, default: string | null, comment: string | null, schema: ValueSchema | null }
export type MysqlPrimaryKey = { name: string | null, columns: MysqlColumnName[] }
export type MysqlUnique = { name: string, columns: MysqlColumnName[], definition: string | null }
export type MysqlIndex = { name: string, columns: MysqlColumnName[], definition: string | null }
export type MysqlCheck = { name: string, columns: MysqlColumnName[], predicate: string | null }
export type MysqlRelation = { name: MysqlRelationName, src: MysqlTableRef, ref: MysqlTableRef, columns: MysqlColumnLink[] }
export type MysqlTableRef = { schema: MysqlSchemaName, table: MysqlTableName }
export type MysqlColumnLink = { src: MysqlColumnName, ref: MysqlColumnName }
export type MysqlType = { schema: MysqlSchemaName, name: MysqlTypeName, values: string[] | null }
export type MysqlSchemaName = string
export type MysqlTableName = string
export type MysqlColumnName = string
export type MysqlColumnType = string
export type MysqlRelationName = string
export type MysqlTypeName = string
export type MysqlTableId = string

export async function getSchema(application: string, url: DatabaseUrlParsed, schema: MysqlSchemaName | undefined, sampleSize: number, logger: Logger): Promise<MysqlSchema> {
    return {tables: [], relations: [], types: []}
}

export function formatSchema(schema: MysqlSchema, inferRelations: boolean): AzimuttSchema {
    return {tables: [], relations: [], types: []}
}
