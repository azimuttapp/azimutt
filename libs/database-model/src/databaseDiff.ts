import {Database} from "./database";
import {z} from "zod";

export const DatabaseDiff = z.object({
    // TODO
}).partial().strict()
export type DatabaseDiff = z.infer<typeof DatabaseDiff>

export function databaseDiff(before: Database, after: Database): DatabaseDiff {
    return {}
}

export function databaseEvolve(db: Database, diff: DatabaseDiff): Database {
    return db
}
