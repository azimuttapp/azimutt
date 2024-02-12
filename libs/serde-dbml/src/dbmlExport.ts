import {Column, ColumnValue, Database, Index, Relation, Table, Type} from "@azimutt/database-model";
import {groupBy, removeUndefined} from "@azimutt/utils";
import {
    JsonDatabase,
    JsonEnum,
    JsonField,
    JsonFieldDefault,
    JsonFieldDefaultType,
    JsonGroup,
    JsonIndex,
    JsonRef,
    JsonRefEndpoint,
    JsonSchema,
    JsonTable
} from "./jsonDatabase";
import {
    ColumnExtensions,
    DatabaseExtensions,
    Group,
    IndexExtensions,
    RelationExtensions,
    TableExtensions,
    TypeExtensions
} from "./extensions";
import { defaultSchema } from "./dbmlImport";

export function exportDatabase(db: Database): JsonDatabase {
    const extensions: DatabaseExtensions = DatabaseExtensions.parse(db.extensions) || {}
    const tablesBySchema = groupBy(db.tables || [], t => t.schema || defaultSchema)
    const typesBySchema = groupBy(db.types || [], t => t.schema || defaultSchema)
    const groupsBySchema = groupBy((extensions.groups || []) as Group[], g => g.schema || defaultSchema)
    const schemas = [...new Set(Object.keys(tablesBySchema).concat(Object.keys(typesBySchema), Object.keys(groupsBySchema)))]
    return {
        schemas: schemas.map(schema => exportSchema(schema, tablesBySchema[schema] || [], [], typesBySchema[schema] || [], groupsBySchema[schema] || []))
            .concat([exportSchema('relations', [], db.relations || [], [], [])])
    }
}

function exportSchema(name: string, tables: Table[], relations: Relation[], types: Type[], groups: Group[]): JsonSchema {
    return {
        name,
        tables: tables.map(exportTable),
        refs: relations.map(exportRelation),
        enums: types.map(exportType),
        tableGroups: [] // groups.map(exportGroup) // FIXME: JSON parser fails with tableGroups (Error: Table "public".undefined don't exist)
    }
}

function exportTable(table: Table): JsonTable {
    const extensions: TableExtensions = TableExtensions.parse(table.extensions) || {}
    const pkComposite: JsonIndex[] = table.primaryKey && table.primaryKey.columns.length > 1 ? [{
        columns: table.primaryKey.columns.map(c => ({type: 'column', value: c})),
        pk: true,
        note: null
    }] : []
    return removeUndefined({
        name: table.name,
        alias: extensions.alias || null,
        note: table.comment || null,
        headerColor: extensions.color || undefined,
        fields: table.columns.map(c => exportColumn(c, table)),
        indexes: pkComposite.concat((table.indexes || []).filter(i => i.columns.length > 1 || !i.unique || i.name).map(exportIndex))
    })
}

function exportColumn(column: Column, table: Table): JsonField {
    const extensions: ColumnExtensions = ColumnExtensions.parse(column.extensions) || {}
    return removeUndefined({
        name: column.name,
        type: { schemaName: null, type_name: column.type, args: null },
        pk: table.primaryKey?.columns.includes(column.name) && table.primaryKey?.columns.length === 1 || false,
        unique: table.indexes?.some(i => i.unique && i.columns.includes(column.name)) || false,
        not_null: column.nullable === false ? true : undefined,
        increment: extensions.increment || undefined,
        dbdefault: column.default !== undefined ? exportColumnDefault(column.default, extensions.defaultType as JsonFieldDefaultType) : undefined,
        note: column.comment || null
    })
}

function exportColumnDefault(d: ColumnValue, type: JsonFieldDefaultType | undefined): JsonFieldDefault | undefined {
    if (d === undefined) return undefined
    if (d === null) return { value: 'null', type: type || 'boolean' }
    if (d === 'null' || d === 'true' || d === 'false') return { value: d.toString(), type: type || 'boolean' }
    if (typeof d === 'string') return { value: d, type: type || 'string' }
    if (typeof d === 'number') return { value: d, type: type || 'number' }
    return { value: d.toString(), type: type || 'boolean' }
}

function exportIndex(index: Index): JsonIndex {
    const extensions: IndexExtensions = IndexExtensions.parse(index.extensions) || {}
    return removeUndefined({
        name: index.name,
        columns: index.columns.map(c => ({type: (extensions.columnTypes || {})[c] || 'column', value: c})),
        unique: index.unique,
        type: index.definition,
        note: index.comment || null
    })
}

function exportRelation(relation: Relation): JsonRef {
    const extensions: RelationExtensions = RelationExtensions.parse(relation.extensions) || {}
    return removeUndefined({
        name: relation.name || null,
        endpoints: [{
            schemaName: relation.ref.schema || null,
            tableName: relation.ref.table,
            fieldNames: relation.columns.map(c => c.ref),
            relation: relation.kind?.endsWith('many') ? '*' : '1'
        }, {
            schemaName: relation.src.schema || null,
            tableName: relation.src.table,
            fieldNames: relation.columns.map(c => c.src),
            relation: relation.kind?.startsWith('one') ? '1' : '*'
        }] as [JsonRefEndpoint, JsonRefEndpoint],
        onDelete: extensions.onDelete || undefined,
        onUpdate: extensions.onUpdate || undefined
    })
}

function exportType(type: Type): JsonEnum {
    const extensions: TypeExtensions = TypeExtensions.parse(type.extensions) || {}
    const valueNotes: Record<string, string> = extensions.notes || {}
    return {
        name: type.name,
        values: (type.values || []).map(v => ({name: v, note: valueNotes[v] || null})),
        note: type.comment || null
    }
}

function exportGroup(group: Group): JsonGroup {
    return {
        name: group.name,
        tables: group.tables.map(t => ({schemaName: t.schema || defaultSchema, tableName: t.table}))
    }
}
