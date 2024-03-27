import {z} from "zod";
import {columnRefFromLegacy, columnRefToLegacy, LegacyColumnRef, LegacyJsValue} from "./legacyDatabase";
import {QueryResults} from "../interfaces/connector";
import {removeUndefined} from "@azimutt/utils";

export const DatabaseQueryResultsColumn = z.object({
    name: z.string(),
    ref: LegacyColumnRef.optional(),
}).strict()
export type DatabaseQueryResultsColumn = z.infer<typeof DatabaseQueryResultsColumn>

export const DatabaseQueryResults = z.object({
    query: z.string(),
    columns: DatabaseQueryResultsColumn.array(),
    rows: LegacyJsValue.array(),
}).strict()
export type DatabaseQueryResults = z.infer<typeof DatabaseQueryResults>

export function queryResultsFromLegacy(r: DatabaseQueryResults): QueryResults {
    return {
        query: r.query,
        attributes: r.columns.map(({name, ref}) => removeUndefined({
            name,
            ref: ref ? columnRefFromLegacy(ref) : undefined
        })),
        rows: r.rows
    }
}

export function queryResultsToLegacy(r: QueryResults): DatabaseQueryResults {
    return {
        query: r.query,
        columns: r.attributes.map(({name, ref}) => removeUndefined({
            name,
            ref: ref ? columnRefToLegacy(ref) : undefined
        })),
        rows: r.rows
    }
}
