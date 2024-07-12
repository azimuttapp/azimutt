import {Static, TNull, TOptional, TSchema, TUnion, Type} from "@sinclair/typebox"

export const sDatabaseUrl = Type.String()
export const sDatabaseName = Type.String()
export const sCatalogName = Type.String()
export const sSchemaName = Type.String()
export const sTableName = Type.String()
export const sTableId = Type.String()
export const sColumnName = Type.String()
export const sColumnType = Type.String()
export const sColumnValue = Type.Union([Type.String(), Type.Number(), Type.Boolean(), Type.Date(), Type.Null(), Type.Unknown()])
export const sRelationName = Type.String()
export const sTypeName = Type.String()
export const sComment = Type.String()
export const sUser = Type.String()
/* export const sType = Type.Intersect([
    Type.Object({
        schema: sSchemaName,
        name: sTypeName,
    }),
    Type.Union([
        Type.Object({values: Type.Union([Type.Array(Type.String()), Type.Null()])}),
        Type.Object({definition: Type.String()})
    ])
]) */
// FIXME: this definition is less correct than the one above but, the previous one does not serialize `values` and `definition` and I can't fix it 🤔
export const sType = Type.Object({
    schema: sSchemaName,
    name: sTypeName,
    values: Nullish(Type.Union([Type.Array(Type.String()), Type.Null()])),
    definition: Nullish(Type.String())
})
export const sColumnRefId = Type.Object({
    table: sTableId,
    column: sColumnName,
})
export const sRelation = Type.Object({
    name: sRelationName,
    src: sColumnRefId,
    ref: sColumnRefId,
})
export const sAzimuttColumnDbStats = Type.Object({
    nulls: Nullish(Type.Number()),
    bytesAvg: Nullish(Type.Number()),
    cardinality: Nullish(Type.Number()),
    commonValues: Nullish(Type.Array(Type.Object({
        value: sColumnValue,
        freq: Type.Number(),
    }))),
    histogram: Nullish(Type.Array(sColumnValue)),
})
export const sColumn = Type.Recursive(Node => Type.Object({
    name: sColumnName,
    type: sColumnType,
    nullable: Nullish(Type.Boolean()),
    default: Nullish(Type.String()),
    comment: Nullish(sComment),
    values: Nullish(Type.Array(sColumnValue)),
    columns: Nullish(Type.Array(Node)),
    stats: Nullish(sAzimuttColumnDbStats),
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
export const sAzimuttTableDbStats = Type.Object({
    rows: Nullish(Type.Number()),
    size: Nullish(Type.Number()),
    sizeIdx: Nullish(Type.Number()),
    scanSeq: Nullish(Type.Number()),
    scanSeqLast: Nullish(Type.String()),
    scanIdx: Nullish(Type.Number()),
    scanIdxLast: Nullish(Type.String()),
    analyzeLast: Nullish(Type.String()),
    vacuumLast: Nullish(Type.String()),
})
export const sAzimuttTable = Type.Object({
    schema: sSchemaName,
    table: sTableName,
    view: Nullish(Type.Boolean()),
    definition: Nullish(Type.String()),
    columns: Type.Array(sColumn),
    primaryKey: Nullish(sPrimaryKey),
    uniques: Nullish(Type.Array(sUnique)),
    indexes: Nullish(Type.Array(sIndex)),
    checks: Nullish(Type.Array(sCheck)),
    comment: Nullish(sComment),
    stats: Nullish(sAzimuttTableDbStats),
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
    options: Type.Optional(Type.Record(Type.String(), Type.String()))
})
export type ParseUrlResponse = Static<typeof ParseUrlResponse>

export const DsSchemaParams = Type.Object({
    database: Type.Optional(sDatabaseName),
    catalog: Type.Optional(sCatalogName),
    schema: Type.Optional(sSchemaName),
    entity: Type.Optional(sTableName),
    user: Type.Optional(sUser),
})
export type DsSchemaParams = Static<typeof DsSchemaParams>
export const DbSchemaParams = Type.Composite([DsSchemaParams, Type.Object({url: sDatabaseUrl})])
export type DbSchemaParams = Static<typeof DbSchemaParams>
export const SchemaResponse = sAzimuttSchema
export type SchemaResponse = Static<typeof SchemaResponse>

export const DsQueryParams = Type.Object({query: Type.String(), user: Type.Optional(sUser)})
export type DsQueryParams = Static<typeof DsQueryParams>
export const DbQueryParams = Type.Composite([DsQueryParams, Type.Object({url: sDatabaseUrl})])
export type DbQueryParams = Static<typeof DbQueryParams>
export const QueryResponse = Type.Strict(sDatabaseQueryResults)
export type QueryResponse = Static<typeof QueryResponse>

export const DsTableStatsParams = Type.Object({
    schema: Type.Optional(sSchemaName),
    table: sTableName,
    user: Type.Optional(sUser),
})
export type DsTableStatsParams = Static<typeof DsTableStatsParams>
export const DbTableStatsParams = Type.Composite([DsTableStatsParams, Type.Object({url: sDatabaseUrl})])
export type DbTableStatsParams = Static<typeof DbTableStatsParams>
export const TableStatsResponse = Type.Strict(sTableStats)
export type TableStatsResponse = Static<typeof TableStatsResponse>

export const DsColumnStatsParams = Type.Object({
    url: sDatabaseUrl,
    schema: Type.Optional(sSchemaName),
    table: sTableName,
    column: sColumnName,
    user: Type.Optional(sUser),
})
export type DsColumnStatsParams = Static<typeof DsColumnStatsParams>
export const DbColumnStatsParams = Type.Composite([DsColumnStatsParams, Type.Object({url: sDatabaseUrl})])
export type DbColumnStatsParams = Static<typeof DbColumnStatsParams>
export const ColumnStatsResponse = Type.Strict(sColumnStats)
export type ColumnStatsResponse = Static<typeof ColumnStatsResponse>

function Nullish<T extends TSchema>(s: T): TOptional<TUnion<[T, TNull]>> {
    return Type.Optional(Type.Union([s, Type.Null()]))
}
