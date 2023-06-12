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
import {errorToString, removeUndefined, zip} from "@azimutt/utils";
import {AzimuttColumn, AzimuttRelation, AzimuttSchema, AzimuttTable, AzimuttType} from "@azimutt/database-types";

export const parseSchema = (schema: string): Promise<PrismaSchema> => {
    try {
        return Promise.resolve(parsePrismaSchema(schema))
    } catch (e) {
        return Promise.reject(errorToString(e))
    }
}

export function formatSchema(schema: PrismaSchema): AzimuttSchema {
    const tables = schema.declarations.flatMap((declaration, index, array) => {
        const prev = array[index-1]
        return declaration.kind === 'model' ? [formatTable(declaration, prev?.kind === 'commentBlock' ? prev : undefined)] : []
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

function formatTable(model: ModelDeclaration, comment: CommentBlock | undefined): { table: AzimuttTable, relations: AzimuttRelation[] } {
    const columns = model.members.flatMap((member, index, array) => {
        const prev = array[index-1]
        return member.kind === 'field' ? [formatColumn(member, prev?.kind === 'commentBlock' ? prev : undefined)] : []
    })
    const fields = model.members.filter((m): m is FieldDeclaration => m.kind === 'field')
    const columnPk = fields.filter(f => f.attributes?.find(a => a.path.value.indexOf('id') >= 0)).map(f => ({columns: [f.name.value]}))
    const columnUniques = fields.filter(f => f.attributes?.find(a => a.path.value.indexOf('unique') >= 0)).map(f => ({columns: [f.name.value]}))
    const relations = fields.flatMap(f => f.attributes?.filter(a => a.path.value.indexOf('relation') >= 0).flatMap(a => formatRelation(model, f, a)) || [])
    const attributes = model.members.filter((m): m is BlockAttribute => m.kind === 'blockAttribute')
    const schema = attributes.find(a => a.path.value[0] === 'schema')
    const dbName = attributes.find(a => a.path.value[0] === 'map')
    const tablePk = attributes.filter(a => a.path.value[0] === 'id').map(formatConstraint)
    const tableUniques = attributes.filter(a => a.path.value[0] === 'unique').map(formatConstraint)
    const tableIndexes = attributes.filter(a => a.path.value[0] === 'index').map(formatConstraint)
    const uniques = columnUniques.concat(tableUniques)
    return {
        table: removeUndefined({
            schema: schema ? (schema.args || []).map(formatSchemaArgument).join('_') : '',
            table: dbName ? (dbName.args || []).map(formatSchemaArgument).join('_') : model.name.value,
            columns: columns,
            // view: false,
            primaryKey: (tablePk.length > 0 ? tablePk[0] : undefined) || (columnPk.length > 0 ? columnPk[0] : undefined),
            uniques: uniques.length > 0 ? uniques : undefined,
            indexes: tableIndexes.length > 0 ? tableIndexes : undefined,
            // checks?: AzimuttCheck[] | null,
            comment: comment ? comment.comments.map(c => c.text).join('\n') : undefined
        }),
        relations: relations
    }
}

function formatColumn(field: FieldDeclaration, comment: CommentBlock | undefined): AzimuttColumn {
    const comments = (comment?.comments || []).concat(field.comment ? [field.comment] : [])
    const dbName = field.attributes?.find(a => a.path.value[0] === 'map')
    const dbType = field.attributes?.find(a => a.path.value[0] === 'db')
    return removeUndefined({
        name: dbName ? (dbName.args || []).map(formatSchemaArgument).join('_') : field.name.value,
        type: (dbType ? formatDbType(dbType) : undefined) || formatPrismaType(field.type),
        nullable: field.type.kind === 'optional' ? true : undefined,
        default: field.attributes
            ?.find(a => a.path.value.indexOf('default') >= 0)
            ?.args
            ?.map(formatSchemaArgument).join(', ') || undefined,
        comment: comments.length > 0 ? comments.map(c => c.text).join('\n') : undefined
    })
}

function formatConstraint(attr: BlockAttribute): {name?: string | null, columns: string[]} {
    const columns = formatFields(findArgument(attr, 'fields')?.expression || attr.args?.find((a): a is SchemaExpression => a.kind !== 'namedArgument'))
    const name = findArgument(attr, 'name')?.expression
    return removeUndefined({
        name: name ? formatSchemaExpression(name) : undefined,
        columns
    })
}

function formatRelation(model: ModelDeclaration, field: FieldDeclaration, attr: FieldAttribute): AzimuttRelation[] {
    const modelSrc = model.name.value
    const modelRef = formatPrismaType(field.type)
    return zip(
        formatFields(findArgument(attr, 'fields')?.expression),
        formatFields(findArgument(attr, 'references')?.expression)
    ).map(([src, ref]) => {
        return {
            name: `fk_${modelSrc}_${src}_${modelRef}_${ref}`,
            src: {schema: '', table: modelSrc, column: src},
            ref: {schema: '', table: modelRef, column: ref}
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
        const prev = array[index-1]
        return member.kind === 'field' ? [formatColumn(member, prev?.kind === 'commentBlock' ? prev : undefined)] : []
    })
    return {
        schema: '',
        name: model.name.value,
        definition: '{'+ columns.map(c => `${c.name}: ${c.type}`).join(', ') +'}'
    }
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

function findArgument(attr: {args?: SchemaArgument[]}, name: string): NamedArgument | undefined {
    return attr.args?.find((a): a is NamedArgument => a.kind === 'namedArgument' && a.name.value === name)
}

// TODO: move to utils
export function deeplyRemoveFields(obj: any, keysToRemove: string[]): any {
    if (Array.isArray(obj)) {
        return obj.map(item => deeplyRemoveFields(item, keysToRemove))
    }

    if (typeof obj === 'object' && obj !== null) {
        const res: { [key: string]: any } = {}
        Object.keys(obj).forEach((key) => {
            if (keysToRemove.indexOf(key) < 0) {
                res[key] = deeplyRemoveFields(obj[key], keysToRemove)
            }
        })
        return res
    }

    return obj
}
