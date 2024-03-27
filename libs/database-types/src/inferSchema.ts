import {distinct, mapValues, removeUndefined} from "@azimutt/utils";
import {AzimuttColumn} from "./schema";

export type ValueSchema = { type: ValueType, values: Value[], nullable?: boolean, nested?: { [key: string]: ValueSchema } }
export type Value = any
export type ValueType = string

// TODO: duplicated to libs/database-model/src/inferSchema.ts, update both
export function valuesToSchema(values: Value[]): ValueSchema {
    if (values.length > 0) {
        return sumSchema(values.map(valueToSchema))
    } else {
        return valueToSchema(undefined)
    }
}

export function schemaToColumns(schema: ValueSchema, flatten: number, path: string[] = []): AzimuttColumn[] {
    // TODO: if string with few values (< 10% of docs), handle it like an enum and add values in comment
    if (schema.nested && flatten > 0) {
        return Object.entries(schema.nested).flatMap(([key, value]) => {
            return [{
                name: path.map(p => p + '.').join('') + key,
                type: value.type,
                nullable: value.nullable
            }, ...schemaToColumns(value, flatten - 1, [...path, key])]
        })
    } else if (schema.nested) {
        return Object.entries(schema.nested).map(([key, value]) => {
            return removeUndefined({
                name: path.map(p => p + '.').join('') + key,
                type: value.type,
                nullable: value.nullable,
                columns: value.nested ? schemaToColumns(value, 0, []) : undefined
            })
        })
    } else {
        return []
    }
}

// 👇️ Private functions, some are exported only for tests
// If you use them, beware of breaking changes!

export function valueToSchema(value: Value): ValueSchema {
    if (Array.isArray(value) && value.length > 0) {
        const schemas = value.map(valueToSchema)
        return cleanSchema({
            type: sumType(schemas.map(s => s.type)) + '[]',
            values: schemas.flatMap(s => s.values),
            nullable: false,
            nested: mergeNested(schemas.map(s => s.nested || {}))
        })
    } else if (typeof value === 'object' && value !== null && value.constructor.name === 'Object') {
        return cleanSchema({
            type: getType(value),
            values: [value],
            nullable: isNullable(value),
            nested: mapValues(value, valueToSchema)
        })
    } else if (isNullable(value)) {
        return {type: getType(value), values: [], nullable: true}
    } else {
        return {type: getType(value), values: [value]}
    }
}

function mergeNested(items: { [key: string]: ValueSchema }[]): { [key: string]: ValueSchema } {
    const nested = {} as { [key: string]: ValueSchema[] }
    items.forEach(i => Object.entries(i).forEach(([key, schema]) => {
        nested[key] = nested[key] ? [...nested[key], schema] : [schema]
    }))
    // TODO: if more than 10 keys, they are all integers or uuids or have the same size or are hex values & have the same type inside => treat this as record instead of object
    return mapValues(nested, sumSchema)
}

function sumSchema(schemas: ValueSchema[]): ValueSchema {
    return cleanSchema({
        type: sumType(schemas.map(s => s.type).filter(t => t !== 'null')) || 'null',
        values: schemas.flatMap(s => s.values),
        nullable: schemas.reduce((acc, schema) => schema.nullable || false || acc, false as boolean),
        nested: mergeNested(schemas.map(s => s.nested || {}))
    })
}

function cleanSchema(schema: ValueSchema): ValueSchema {
    const res: ValueSchema = {type: schema.type, values: schema.values}
    if (schema.nested && Object.keys(schema.nested).length > 0) {
        res.nested = schema.nested
    }
    if (schema.nullable) {
        res.nullable = schema.nullable
    }
    return res
}

function getType(value: Value): ValueType {
    if (value === undefined || value === null) {
        return 'null'
    } else if (Array.isArray(value)) {
        return value.length > 0 ? sumType(value.map(getType)) + '[]' : '[]'
    } else if (typeof value === 'object') {
        return value.constructor.name
    } else {
        return typeof value
    }
}

export function sumType(types: ValueType[]): ValueType {
    types = distinct(types)
    types = types.some(t => t !== '[]' && t.endsWith('[]')) ? types.filter(t => t !== '[]') : types
    return types.map(t => t.indexOf('|') === -1 ? t : `(${t})`).join('|')
}

function isNullable(value: Value): boolean {
    return value === null || value === undefined
}
