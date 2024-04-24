import {z} from "zod";
import {Database, Entity, EntityName, Namespace} from "./database";

// FIXME: Work In Progress

export const EntityDiff = Namespace.extend({
    name: EntityName,
})
export type EntityDiff = z.infer<typeof EntityDiff>

export const DatabaseDiff = z.object({
    entities: z.object({
        created: Entity.array(),
        deleted: Entity.array(),
        updated: EntityDiff.array(),
    }).partial().strict()
}).partial().strict().describe('DatabaseDiff')
export type DatabaseDiff = z.infer<typeof DatabaseDiff>

type Diff<T> = {created: T, deleted: T, updated: [T, T]}

export function databaseDiff(before: Database, after: Database): DatabaseDiff {
    return {}
}

export function databaseEvolve(db: Database, diff: DatabaseDiff): Database {
    return db
}
