import {z} from "zod";
import {Diff, diffBy, equalDeep, removeEmpty, removeFieldsDeep} from "@azimutt/utils";
import {Attribute, Database, Entity, Index, Relation, Type} from "./database";
import {attributePathToId, entityToId, relationToId, typeToId} from "./databaseUtils";

// FIXME: Work In Progress, make it more specific

export const zDiff = <T>(schema: z.ZodType<T>) => z.object({
    left: schema.array().optional(),
    right: schema.array().optional(),
    both: z.object({left: schema, right: schema}).array().optional()
}).strict()
export const EntityDiff = z.object({
    left: Entity,
    right: Entity,
    attrs: zDiff(Attribute).optional(),
    indexes: zDiff(Index).optional(),
}).describe('EntityDiff')
export type EntityDiff = z.infer<typeof EntityDiff>
export const DatabaseDiff = z.object({
    entities: z.object({left: Entity.array().optional(), right: Entity.array().optional(), both: EntityDiff.array().optional()}).optional(),
    relations: zDiff(Relation).optional(),
    types: zDiff(Type).optional(),
}).strict().describe('DatabaseDiff')
export type DatabaseDiff = z.infer<typeof DatabaseDiff>


export function databaseDiff(leftDb: Database, rightDb: Database): DatabaseDiff {
    const {left: leftEntities, right: rightEntities, both: commonEntities} = diffBy(leftDb.entities || [], rightDb.entities || [], entityToId)
    const updatedEntities = commonEntities?.map(entity => {
        return removeEmpty({
            ...entity,
            attrs: defaultDiff(entity.left.attrs?.map(cleanStats) || [], entity.right.attrs?.map(cleanStats) || [], a => a.name),
            indexes: defaultDiff(entity.left.indexes?.map(cleanStats) || [], entity.right.indexes?.map(cleanStats) || [], indexToId)
        })
    }).filter(d => d.attrs || d.indexes)

    return removeEmpty({
        entities: removeEmpty({
            left: leftEntities,
            right: rightEntities,
            both: updatedEntities
        }),
        relations: defaultDiff(leftDb.relations || [], rightDb.relations || [], relationToId),
        types: defaultDiff(leftDb.types || [], rightDb.types || [], typeToId)
    })
}

function defaultDiff<T extends object, K extends keyof any>(leftArr: T[], rightArr: T[], getKey: (t: T) => K): Diff<T> {
    const {left, right, both} = diffBy(leftArr, rightArr, getKey)
    return removeEmpty({
        left,
        right,
        both: both?.filter(({left, right}) => !equalDeep(left, right))
    })
}

// TODO
export function databaseEvolve(db: Database, diff: DatabaseDiff): Database {
    return db
}

const indexToId = (i: Index): string => `${i.name}(${i.attrs.map(attributePathToId).join(', ')})`
const cleanStats = <T>(obj: T): T => removeFieldsDeep(obj, ['stats'])
