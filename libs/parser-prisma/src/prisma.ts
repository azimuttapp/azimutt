import {parsePrismaSchema, PrismaSchema} from "@loancrate/prisma-schema-parser";
import {
    CommentBlock,
    FieldAttribute,
    FieldDeclaration,
    ModelDeclaration, NamedArgument,
    PrismaType,
    SchemaArgument,
    SchemaExpression
} from "@loancrate/prisma-schema-parser/dist/ast";
import {removeUndefined, zip} from "@azimutt/utils";
import {AzimuttColumn, AzimuttRelation, AzimuttSchema, AzimuttTable} from "@azimutt/database-types";

export const parseSchema = (schema: string): PrismaSchema => parsePrismaSchema(schema)

export function formatSchema(schema: PrismaSchema): AzimuttSchema {
    const tables = schema.declarations.filter((d): d is ModelDeclaration => d.kind === 'model').map(formatTable)
    return {
        tables: tables.map(t => t.table),
        relations: tables.flatMap(t => t.relations)
    }
}

// 👇️ Private functions, some are exported only for tests
// If you use them, beware of breaking changes!

// Azimutt helpers

function formatTable(model: ModelDeclaration): { table: AzimuttTable, relations: AzimuttRelation[] } {
    const fields = model.members.filter((m): m is FieldDeclaration => m.kind === 'field')
    const pk = fields.filter(f => f.attributes?.find(a => a.path.value.indexOf('id') >= 0)).map(f => f.name.value)
    const uniques = fields.filter(f => f.attributes?.find(a => a.path.value.indexOf('unique') >= 0)).map(f => [f.name.value])
    const relations = fields.flatMap(f => f.attributes?.filter(a => a.path.value.indexOf('relation') >= 0).flatMap(a => formatRelation(model, f, a)) || [])
    const comments = model.members.filter((m): m is CommentBlock => m.kind === 'commentBlock').flatMap(cb => cb.comments.map(c => c.text))
    return {
        table: removeUndefined({
            schema: '',
            table: model.name.value,
            columns: fields.map(formatColumn),
            // view: false,
            primaryKey: pk.length > 0 ? {columns: pk} : undefined,
            uniques: uniques.length > 0 ? uniques.map(u => ({columns: u})) : undefined,
            // indexes?: AzimuttIndex[] | null,
            // checks?: AzimuttCheck[] | null,
            comment: comments.length > 0 ? comments.join('\n\n') : undefined
        }),
        relations: relations
    }
}

function formatColumn(field: FieldDeclaration): AzimuttColumn {
    return removeUndefined({
        name: field.name.value,
        type: formatPrismaType(field.type),
        nullable: field.type.kind === 'optional' ? true : undefined,
        default: field.attributes
            ?.find(a => a.path.value.indexOf('default') >= 0)
            ?.args
            ?.map(formatSchemaArgument).join(', ') || undefined,
        comment: field.comment?.text || undefined
    })
}

function formatRelation(model: ModelDeclaration, field: FieldDeclaration, attr: FieldAttribute): AzimuttRelation[] {
    const modelSrc = model.name.value
    const modelRef = formatPrismaType(field.type)
    return zip(
        formatRelationColumns(findArgument(attr, 'fields')),
        formatRelationColumns(findArgument(attr, 'references'))
    ).map(([src, ref]) => {
        return {
            name: `fk_${modelSrc}_${src}_${modelRef}_${ref}`,
            src: {schema: '', table: modelSrc, column: src},
            ref: {schema: '', table: modelRef, column: ref}
        }
    })
}

function formatRelationColumns(arg: NamedArgument | undefined): string[] {
    if (arg?.expression.kind === 'array') {
        return arg.expression.items.map(formatSchemaExpression)
    } else {
        return []
    }
}

// Prisma helpers

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

function findArgument(attr: FieldAttribute, name: string): NamedArgument | undefined {
    return attr.args?.find((a): a is NamedArgument => a.kind === 'namedArgument' && a.name.value === name)
}
