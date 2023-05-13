import {OptionalModifier, Static, TNull, TSchema, TUnion, Type} from "@sinclair/typebox";

export const sDatabaseUrl = Type.String()
export const sSchemaName = Type.String()
export const sTableName = Type.String()
export const sColumnName = Type.String()
export const sColumnType = Type.String()
export const sRelationName = Type.String()
export const sTypeName = Type.String()
export const sComment = Type.String()
export const sType = Type.Intersect([
    Type.Object({
        schema: sSchemaName,
        name: sTypeName,
    }),
    Type.Union([
        Type.Object({values: Type.Union([Type.Array(Type.String()), Type.Null()])}),
        Type.Object({definition: Type.String()})
    ])
])
export const sColumnRef = Type.Object({
    schema: sSchemaName,
    table: sTableName,
    column: sColumnName,
})
export const sRelation = Type.Object({
    name: sRelationName,
    src: sColumnRef,
    ref: sColumnRef,
})
export const sColumn = Type.Object({
    name: sColumnName,
    type: sColumnType,
    nullable: Nullish(Type.Boolean()),
    default: Nullish(Type.String()),
    comment: Nullish(sComment),
})
export const sCheck = Type.Object({
    name: Nullish(Type.String()),
    columns: Type.Array(sColumnName),
    predicate: Nullish(Type.String()),
})
export const sIndex = Type.Object({
    name: Nullish(Type.String()),
    columns: Type.Array(sColumnName),
    definition: Nullish(Type.String()),
})
export const sUnique = Type.Object({
    name: Nullish(Type.String()),
    columns: Type.Array(sColumnName),
    definition: Nullish(Type.String()),
})
export const sPrimaryKey = Type.Object({
    name: Nullish(Type.String()),
    columns: Type.Array(sColumnName),
})
export const sAzimuttTable = Type.Object({
    schema: sSchemaName,
    table: sTableName,
    view: Nullish(Type.Boolean()),
    columns: Type.Array(sColumn),
    primaryKey: Nullish(sPrimaryKey),
    uniques: Nullish(Type.Array(sUnique)),
    indexes: Nullish(Type.Array(sIndex)),
    checks: Nullish(Type.Array(sCheck)),
    comment: Nullish(sComment),
})
export const sAzimuttSchema = Type.Object({
    tables: Type.Array(sAzimuttTable),
    relations: Type.Array(sRelation),
    types: Nullish(Type.Array(sType))
})

export const ErrorResponse = Type.Object({error: Type.String()})
export type ErrorResponse = Static<typeof ErrorResponse>
export const FailureResponse = Type.Object({
    statusCode: Type.Number(),
    code: Type.Optional(Type.String()),
    error: Type.String(),
    message: Type.String()
})
export type FailureResponse = Static<typeof FailureResponse>

export const GetSchemaParams = Type.Object({url: sDatabaseUrl, schema: Type.Optional(sSchemaName)})
export type GetSchemaParams = Static<typeof GetSchemaParams>
export const GetSchemaResponse = sAzimuttSchema
export type GetSchemaResponse = Static<typeof GetSchemaResponse>

function Nullish<T extends TSchema>(s: T): TUnion<[T, TNull]> & { modifier: typeof OptionalModifier } {
    return Type.Optional(Type.Union([s, Type.Null()]))
}
