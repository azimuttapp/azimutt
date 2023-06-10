import {Static, TNull, TOptional, TSchema, TUnion, Type} from "@sinclair/typebox"

export const sDatabaseUrl = Type.String()
export const sSchemaName = Type.String()
export const sTableName = Type.String()
export const sTableId = Type.String()
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
export const sColumnRefId = Type.Object({
    table: sTableId,
    column: sColumnName,
})
export const sRelation = Type.Object({
    name: sRelationName,
    src: sColumnRef,
    ref: sColumnRef,
})
export const sColumn = Type.Recursive(Node => Type.Object({
    name: sColumnName,
    type: sColumnType,
    nullable: Nullish(Type.Boolean()),
    default: Nullish(Type.String()),
    comment: Nullish(sComment),
    columns: Nullish(Type.Array(Node)),
}))
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

export const sJsValue = Type.Recursive(Node => Type.Union([
    Type.String(),
    Type.Number(),
    Type.Boolean(),
    Type.Null(),
    Type.Array(Node),
    Type.Record(Type.String(), Node)
]))
export const sDatabaseQueryResultsColumn = Type.Object({
    name: Type.String(),
    ref: Type.Optional(sColumnRefId)
})
export const sDatabaseQueryResults = Type.Object({
    query: Type.String(),
    columns: Type.Array(sDatabaseQueryResultsColumn),
    // @ts-expect-error: Type instantiation is excessively deep and possibly infinite.
    rows: Type.Array(sJsValue)
})

export const sColumnValue = Type.Union([Type.String(), Type.Number(), Type.Boolean(), Type.Date(), Type.Null(), Type.Unknown()])
export const sTableSampleValues = Type.Record(sColumnName, sColumnValue)
export const sTableStats = Type.Object({
    schema: Type.Union([sSchemaName, Type.Null()]),
    table: sTableName,
    rows: Type.Number(),
    sample_values: sTableSampleValues
})

export const sColumnCommonValue = Type.Object({
    value: sColumnValue,
    count: Type.Number()
})
export const sColumnStats = Type.Object({
    schema: Type.Union([sSchemaName, Type.Null()]),
    table: sTableName,
    column: sColumnName,
    type: sColumnType,
    rows: Type.Number(),
    nulls: Type.Number(),
    cardinality: Type.Number(),
    common_values: Type.Array(sColumnCommonValue)
})

// endpoints Params & Responses

export const ErrorResponse = Type.Object({error: Type.String()})
export type ErrorResponse = Static<typeof ErrorResponse>
export const FailureResponse = Type.Object({
    statusCode: Type.Number(),
    code: Type.Optional(Type.String()),
    error: Type.String(),
    message: Type.String()
})
export type FailureResponse = Static<typeof FailureResponse>

export const ParseUrlParams = Type.Object({url: sDatabaseUrl})
export type ParseUrlParams = Static<typeof ParseUrlParams>
export const ParseUrlResponse = Type.Object({
    full: sDatabaseUrl,
    kind: Type.Optional(Type.String()),
    user: Type.Optional(Type.String()),
    pass: Type.Optional(Type.String()),
    host: Type.Optional(Type.String()),
    port: Type.Optional(Type.Number()),
    db: Type.Optional(Type.String()),
    options: Type.Optional(Type.String())
})
export type ParseUrlResponse = Static<typeof ParseUrlResponse>

export const GetSchemaParams = Type.Object({url: sDatabaseUrl, schema: Type.Optional(sSchemaName)})
export type GetSchemaParams = Static<typeof GetSchemaParams>
export const GetSchemaResponse = sAzimuttSchema
export type GetSchemaResponse = Static<typeof GetSchemaResponse>

export const DbQueryParams = Type.Object({url: sDatabaseUrl, query: Type.String()})
export type DbQueryParams = Static<typeof DbQueryParams>
export const DbQueryResponse = Type.Strict(sDatabaseQueryResults)
export type DbQueryResponse = Static<typeof DbQueryResponse>

export const GetTableStatsParams = Type.Object({
    url: sDatabaseUrl,
    schema: Type.Optional(sSchemaName),
    table: sTableName
})
export type GetTableStatsParams = Static<typeof GetTableStatsParams>
export const GetTableStatsResponse = Type.Strict(sTableStats)
export type GetTableStatsResponse = Static<typeof GetTableStatsResponse>

export const GetColumnStatsParams = Type.Object({
    url: sDatabaseUrl,
    schema: Type.Optional(sSchemaName),
    table: sTableName,
    column: sColumnName
})
export type GetColumnStatsParams = Static<typeof GetColumnStatsParams>
export const GetColumnStatsResponse = Type.Strict(sColumnStats)
export type GetColumnStatsResponse = Static<typeof GetColumnStatsResponse>

function Nullish<T extends TSchema>(s: T): TOptional<TUnion<[T, TNull]>> {
    return Type.Optional(Type.Union([s, Type.Null()]))
}
