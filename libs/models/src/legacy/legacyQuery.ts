import {z} from "zod";
import {removeUndefined} from "@azimutt/utils";
import {QueryResults} from "../interfaces/connector";
import {columnRefFromLegacy, columnRefToLegacy, LegacyColumnRef, LegacyJsValue} from "./legacyDatabase";

export const LegacyDatabaseQueryResultsColumn = z.object({
    name: z.string(),
    ref: LegacyColumnRef.optional(),
}).strict()
export type LegacyDatabaseQueryResultsColumn = z.infer<typeof LegacyDatabaseQueryResultsColumn>

export const LegacyDatabaseQueryResults = z.object({
    query: z.string(),
    columns: LegacyDatabaseQueryResultsColumn.array(),
    rows: LegacyJsValue.array(),
}).strict().describe('LegacyDatabaseQueryResults')
export type LegacyDatabaseQueryResults = z.infer<typeof LegacyDatabaseQueryResults>

export function queryResultsFromLegacy(r: LegacyDatabaseQueryResults): QueryResults {
    return {
        query: r.query,
        attributes: r.columns.map(({name, ref}) => removeUndefined({
            name,
            ref: ref ? columnRefFromLegacy(ref) : undefined
        })),
        rows: r.rows
    }
}

export function queryResultsToLegacy(r: QueryResults): LegacyDatabaseQueryResults {
    return {
        query: r.query,
        columns: r.attributes.map(({name, ref}) => removeUndefined({
            name,
            ref: ref ? columnRefToLegacy(ref) : undefined
        })),
        rows: r.rows
    }
}
