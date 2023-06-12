import {EnumDeclaration, parsePrismaSchema, PrismaSchema} from "@loancrate/prisma-schema-parser";
import {
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
    return {
        tables: tables.map(t => t.table),
        relations: tables.flatMap(t => t.relations),
        types: schema.declarations.filter((d): d is EnumDeclaration => d.kind === 'enum').map(formatType)
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
    const pk = fields.filter(f => f.attributes?.find(a => a.path.value.indexOf('id') >= 0)).map(f => f.name.value)
    const uniques = fields.filter(f => f.attributes?.find(a => a.path.value.indexOf('unique') >= 0)).map(f => [f.name.value])
    const relations = fields.flatMap(f => f.attributes?.filter(a => a.path.value.indexOf('relation') >= 0).flatMap(a => formatRelation(model, f, a)) || [])
    return {
        table: removeUndefined({
            schema: '',
            table: model.name.value,
            columns: columns,
            // view: false,
            primaryKey: pk.length > 0 ? {columns: pk} : undefined,
            uniques: uniques.length > 0 ? uniques.map(u => ({columns: u})) : undefined,
            // indexes?: AzimuttIndex[] | null,
            // checks?: AzimuttCheck[] | null,
            comment: comment ? comment.comments.map(c => c.text).join('\n') : undefined
        }),
        relations: relations
    }
}

function formatColumn(field: FieldDeclaration, comment: CommentBlock | undefined): AzimuttColumn {
    const comments = (comment?.comments || []).concat(field.comment ? [field.comment] : [])
    return removeUndefined({
        name: field.name.value,
        type: formatPrismaType(field.type),
        nullable: field.type.kind === 'optional' ? true : undefined,
        default: field.attributes
            ?.find(a => a.path.value.indexOf('default') >= 0)
            ?.args
            ?.map(formatSchemaArgument).join(', ') || undefined,
        comment: comments.length > 0 ? comments.map(c => c.text).join('\n') : undefined
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

function formatType(e: EnumDeclaration): AzimuttType {
    return {
        schema: '',
        name: e.name.value,
        values: e.members.filter((m): m is EnumValue => m.kind === 'enumValue').map(v => v.name.value)
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
