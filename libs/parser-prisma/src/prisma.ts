import {EnumDeclaration, parsePrismaSchema, PrismaSchema} from "@loancrate/prisma-schema-parser";
import {
    BlockAttribute,
    CommentBlock,
    EnumValue,
    FieldAttribute,
    FieldDeclaration,
    ModelDeclaration,
    NamedArgument,
    PrismaType,
    SchemaArgument,
    SchemaExpression
} from "@loancrate/prisma-schema-parser/dist/ast";
import {collect, collectOne, errorToString, removeUndefined, zip} from "@azimutt/utils";
import {
    AzimuttColumn,
    AzimuttRelation,
    AzimuttSchema,
    AzimuttTable,
    AzimuttType,
    SchemaName,
    TableName
} from "@azimutt/database-types";

export const parseSchema = (schema: string): Promise<PrismaSchema> => {
    try {
        return Promise.resolve(parsePrismaSchema(schema))
    } catch (e) {
        return Promise.reject(errorToString(e))
    }
}

export function formatSchema(schema: PrismaSchema): AzimuttSchema {
    const tables = schema.declarations.flatMap((declaration, index, array) => {
        const prev = array[index - 1]
        return declaration.kind === 'model' ? [formatTable(schema, declaration, prev?.kind === 'commentBlock' ? prev : undefined)] : []
    })
    const enums = schema.declarations.filter((d): d is EnumDeclaration => d.kind === 'enum').map(formatEnum)
    const types = schema.declarations.filter((d): d is ModelDeclaration => d.kind === 'type').map(formatType)
    return {
        tables: tables.map(t => t.table),
        relations: tables.flatMap(t => t.relations),
        types: enums.concat(types)
    }
}

// 👇️ Private functions, some are exported only for tests
// If you use them, beware of breaking changes!

// Azimutt helpers

function formatTable(schema: PrismaSchema, model: ModelDeclaration, comment: CommentBlock | undefined): { table: AzimuttTable, relations: AzimuttRelation[] } {
    const columns = model.members.flatMap((member, index, array) => {
        const prev = array[index - 1]
        return member.kind === 'field' ? [formatColumn(member, prev?.kind === 'commentBlock' ? prev : undefined)] : []
    })
    const fields = model.members.filter((m): m is FieldDeclaration => m.kind === 'field')
    const columnPk = collectOne(fields, f => f.attributes?.find(a => a.path.value.indexOf('id') >= 0) ? {columns: [f.name.value]} : undefined)
    const columnUniques = fields.filter(f => f.attributes?.find(a => a.path.value.indexOf('unique') >= 0)).map(f => ({columns: [f.name.value]}))
    const attributes = model.members.filter((m): m is BlockAttribute => m.kind === 'blockAttribute')
    const tablePk = collectOne(attributes, a => a.path.value[0] === 'id' ? formatConstraint(a) : undefined)
    const tableUniques = collect(attributes, a => a.path.value[0] === 'unique' ? formatConstraint(a) : undefined)
    const tableIndexes = collect(attributes, a => a.path.value[0] === 'index' ? formatConstraint(a) : undefined)
    const uniques = columnUniques.concat(tableUniques)
    return {
        table: removeUndefined({
            schema: getTableSchema(model),
            table: getTableName(model),
            columns: columns,
            // view: false, // views are not parsed by @loancrate/prisma-schema-parser :/
            primaryKey: tablePk || columnPk,
            uniques: uniques.length > 0 ? uniques : undefined,
            indexes: tableIndexes.length > 0 ? tableIndexes : undefined,
            checks: undefined, // no CHECK constraint in Prisma Schema :/
            comment: comment ? comment.comments.map(c => c.text).join('\n') : undefined
        }),
        relations: fields.flatMap(f => f.attributes?.filter(a => a.path.value.indexOf('relation') >= 0).flatMap(a => formatRelation(schema, model, f, a)) || [])
    }
}

function formatColumn(field: FieldDeclaration, comment: CommentBlock | undefined): AzimuttColumn {
    const comments = (comment?.comments || []).concat(field.comment ? [field.comment] : [])
    const dbType = field.attributes?.find(a => a.path.value[0] === 'db')
    return removeUndefined({
        name: getColumnName(field),
        type: (dbType ? formatDbType(dbType) : undefined) || formatPrismaType(field.type),
        nullable: field.type.kind === 'optional' ? true : undefined,
        default: field.attributes
            ?.find(a => a.path.value.indexOf('default') >= 0)
            ?.args
            ?.map(formatSchemaArgument).join(', ') || undefined,
        comment: comments.length > 0 ? comments.map(c => c.text).join('\n') : undefined
    })
}

function formatConstraint(attr: BlockAttribute): { name?: string | null, columns: string[] } {
    const columns = formatFields(getNamedArgument(attr, 'fields')?.expression || getFirstUnnamedArgument(attr))
    const name = getNamedArgument(attr, 'name')?.expression
    return removeUndefined({
        name: name ? formatSchemaExpression(name) : undefined,
        columns
    })
}

function formatRelation(schema: PrismaSchema, model: ModelDeclaration, field: FieldDeclaration, attr: FieldAttribute): AzimuttRelation[] {
    const srcTableName = getTableName(model)
    const refModelName = formatPrismaType(field.type)
    const refModel = getModel(schema, refModelName)
    const refTableName = refModel ? getTableName(refModel) : refModelName
    return zip(
        formatFields(getNamedArgument(attr, 'fields')?.expression),
        formatFields(getNamedArgument(attr, 'references')?.expression)
    ).map(([src, ref]) => {
        const srcField = getField(model, src)
        const srcFieldName = srcField ? getColumnName(srcField) : src
        const refField = refModel ? getField(refModel, ref) : undefined
        const refFieldName = refField ? getColumnName(refField) : ref
        return {
            name: `fk_${srcTableName}_${srcFieldName}_${refTableName}_${refFieldName}`,
            src: {schema: getTableSchema(model), table: srcTableName, column: srcFieldName},
            ref: {schema: refModel ? getTableSchema(refModel) : '', table: refTableName, column: refFieldName}
        }
    })
}

function formatFields(expr: SchemaExpression | undefined): string[] {
    if (expr?.kind === 'array') {
        return expr?.items.map(formatSchemaExpression)
    } else {
        return []
    }
}

function formatEnum(e: EnumDeclaration): AzimuttType {
    return {
        schema: '',
        name: e.name.value,
        values: e.members.filter((m): m is EnumValue => m.kind === 'enumValue').map(v => v.name.value)
    }
}

function formatType(model: ModelDeclaration): AzimuttType {
    const columns = model.members.flatMap((member, index, array) => {
        const prev = array[index - 1]
        return member.kind === 'field' ? [formatColumn(member, prev?.kind === 'commentBlock' ? prev : undefined)] : []
    })
    return {
        schema: '',
        name: model.name.value,
        definition: '{' + columns.map(c => `${c.name}: ${c.type}`).join(', ') + '}'
    }
}

function getTableSchema(model: ModelDeclaration): SchemaName {
    const dbSchema = model.members.find((m): m is BlockAttribute => m.kind === 'blockAttribute' && m.path.value[0] === 'schema')
    return dbSchema ? (dbSchema.args || []).map(formatSchemaArgument).join('_') : ''
}

function getTableName(model: ModelDeclaration): TableName {
    const dbName = model.members.find((m): m is BlockAttribute => m.kind === 'blockAttribute' && m.path.value[0] === 'map')
    return dbName ? (dbName.args || []).map(formatSchemaArgument).join('_') : model.name.value
}

function getColumnName(field: FieldDeclaration) {
    const dbName = field.attributes?.find(a => a.path.value[0] === 'map')
    return dbName ? (dbName.args || []).map(formatSchemaArgument).join('_') : field.name.value
}

// Prisma helpers

function formatDbType(attr: FieldAttribute): string | undefined {
    if (attr.path.value[0] === 'db') {
        return attr.path.value[1] + '(' + (attr.args || []).map(formatSchemaArgument).join(', ') + ')'
    } else {
        return undefined
    }
}

function formatPrismaType(type: PrismaType): string {
    if (type.kind === 'typeId') {
        return type.name.value
    } else if (type.kind === 'unsupported') {
        return type.type.value
    } else if (type.kind === 'list') {
        return formatPrismaType(type.type) + '[]'
    } else if (type.kind === 'optional') {
        return formatPrismaType(type.type)
    } else if (type.kind === 'required') {
        return formatPrismaType(type.type)
    } else {
        return 'unknown-type' // should never happen
    }
}

function formatSchemaArgument(arg: SchemaArgument): string {
    if (arg.kind === 'namedArgument') {
        return formatSchemaExpression((arg.expression))
    } else {
        return formatSchemaExpression(arg)
    }
}

function formatSchemaExpression(expr: SchemaExpression): string {
    if (expr.kind === 'literal') {
        if (typeof expr.value === 'string') return expr.value
        if (typeof expr.value === 'number') return expr.value.toString()
        if (typeof expr.value === 'boolean') return expr.value ? 'true' : 'false'
        return 'unknown-literal' // should never happen
    } else if (expr.kind === 'path') {
        return expr.value.join('.')
    } else if (expr.kind === 'array') {
        return '[' + expr.items.map(formatSchemaExpression).join(', ') + ']'
    } else if (expr.kind === 'functionCall') {
        return expr.path.value.join('.') + '(' + (expr.args ? expr.args.map(formatSchemaArgument).join(', ') : '') + ')'
    } else {
        return 'unknown-expression' // should never happen
    }
}

function getModel(schema: PrismaSchema, name: string): ModelDeclaration | undefined {
    return schema.declarations.find((d): d is ModelDeclaration => d.kind === 'model' && d.name.value === name)
}

function getField(model: ModelDeclaration, name: string): FieldDeclaration | undefined {
    return model.members.find((m): m is FieldDeclaration => m.kind === 'field' && m.name.value === name)
}

function getNamedArgument(attr: { args?: SchemaArgument[] }, name: string): NamedArgument | undefined {
    return attr.args?.find((a): a is NamedArgument => a.kind === 'namedArgument' && a.name.value === name)
}

function getFirstUnnamedArgument(attr: BlockAttribute): SchemaExpression | undefined {
    return attr.args?.find((a): a is SchemaExpression => a.kind !== 'namedArgument')
}
