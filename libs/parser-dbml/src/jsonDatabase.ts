// The JSON representation for DBML Database (export & parse JSON format).
// as I can't build a DBML `Database` class manually, I generate it using the JSON parser: `(new Parser(undefined)).parse(JSON.stringify(json), 'json')`

export type JsonDatabase = {
    schemas: JsonSchema[]
}

export type JsonSchema = {
    name: string
    note?: string
    tables: JsonTable[]
    refs: JsonRef[]
    enums: JsonEnum[]
    tableGroups: JsonGroup[]
}

export type JsonTable = {
    name: string
    alias: string | null
    note: string | null
    headerColor?: string
    fields: JsonField[]
    indexes: JsonIndex[]
}

export type JsonField = {
    name: string
    type: JsonFieldType
    pk: boolean
    unique: boolean
    not_null?: boolean
    increment?: boolean
    dbdefault?: JsonFieldDefault
    note: string | null
}

export type JsonFieldType = {
    schemaName: string | null,
    type_name: string,
    args: string | null
}

export type JsonFieldDefault = {
    value: string | number,
    type: JsonFieldDefaultType
}

export type JsonFieldDefaultType = 'string' | 'number' | 'boolean' | 'expression'

export type JsonIndex = {
    name?: string
    columns: JsonIndexColumn[]
    pk?: boolean
    unique?: boolean
    type?: string
    note: string | null
}

export type JsonIndexColumn = {
    type: 'column' | 'expression',
    value: string
}

export type JsonRef = {
    name: string | null
    endpoints: [JsonRefEndpoint, JsonRefEndpoint]
    onDelete?: string
    onUpdate?: string
}

export type JsonRefEndpoint = {
    schemaName: string | null
    tableName: string
    fieldNames: string[]
    relation: JsonRefEndpointKind
}

export type JsonRefEndpointKind = '1' | '*'

export type JsonEnum = {
    name: string,
    values: JsonEnumValue[],
    note: string | null
}

export type JsonEnumValue = {
    name: string,
    note: string | null
}

export type JsonGroup = {
    name: string,
    tables: JsonTableRef[]
}

export type JsonTableRef = {
    schemaName: string,
    tableName: string
}
