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
import {collect, collectOne, errorToString, removeEmpty, removeUndefined, zip} from "@azimutt/utils";
import {
    Attribute,
    AttributeName,
    AttributePath,
    Database,
    Entity,
    EntityName,
    Index,
    ParserErrorLevel,
    ParserResult,
    PrimaryKey,
    Relation,
    SchemaName,
    Type
} from "@azimutt/models";
import packageJson from "../package.json";

export function parsePrisma(content: string, opts: { context?: Database } = {}): ParserResult<Database> {
    try {
        return ParserResult.success(buildDatabase(parsePrismaSchema(content)))
    } catch (e) {
        return ParserResult.failure([{message: errorToString(e), kind: 'PrismaParserError', level: ParserErrorLevel.enum.error, offset: {start: 0, end: 0}, position: {start: {line: 0, column: 0}, end: {line: 0, column: 0}}}])
    }
}

export function generatePrisma(database: Database): string {
    return 'Prisma generator not implemented'
}

// 👇️ Private functions, some are exported only for tests
// If you use them, beware of breaking changes!

function buildDatabase(schema: PrismaSchema): Database {
    const entities = schema.declarations.flatMap((declaration, index, array) => {
        const prev = array[index - 1]
        return declaration.kind === 'model' ? [buildEntity(schema, declaration, prev?.kind === 'commentBlock' ? prev : undefined)] : []
    })
    const enums = schema.declarations.filter((d): d is EnumDeclaration => d.kind === 'enum').map(buildEnum)
    const types = schema.declarations.filter((d): d is ModelDeclaration => d.kind === 'type').map(buildType)
    return removeEmpty({
        entities: entities.map(t => t.entity),
        relations: entities.flatMap(t => t.relations),
        types: enums.concat(types),
        extra: {
            source: `Prisma parser <${packageJson.version}>`
        }
    })
}

function buildEntity(schema: PrismaSchema, model: ModelDeclaration, comment: CommentBlock | undefined): { entity: Entity, relations: Relation[] } {
    const attrs: Attribute[] = model.members.flatMap((member, index, array) => {
        const prev = array[index - 1]
        return member.kind === 'field' ? [buildAttribute(member, prev?.kind === 'commentBlock' ? prev : undefined)] : []
    })
    const fields: FieldDeclaration[] = model.members.filter((m): m is FieldDeclaration => m.kind === 'field')
    const attrPk: PrimaryKey | undefined = collectOne(fields, f => f.attributes?.find(a => a.path.value.indexOf('id') >= 0) ? {attrs: [[f.name.value]]} : undefined)
    const attrUniques: Index[] = fields.filter(f => f.attributes?.find(a => a.path.value.indexOf('unique') >= 0)).map(f => ({attrs: [[f.name.value]], unique: true}))
    const attributes: BlockAttribute[] = model.members.filter((m): m is BlockAttribute => m.kind === 'blockAttribute')
    const entityPk: PrimaryKey | undefined = collectOne(attributes, a => a.path.value[0] === 'id' ? formatConstraint(a) : undefined)
    const entityUniques: Index[] = collect(attributes, a => a.path.value[0] === 'unique' ? {...formatConstraint(a), unique: true} : undefined)
    const entityIndexes: Index[] = collect(attributes, a => a.path.value[0] === 'index' ? formatConstraint(a) : undefined)
    return {
        entity: removeEmpty({
            schema: getEntitySchema(model),
            name: getEntityName(model),
            // kind: 'view', // views are not parsed by @loancrate/prisma-schema-parser :/
            attrs: attrs,
            pk: entityPk || attrPk,
            indexes: attrUniques.concat(entityUniques, entityIndexes),
            checks: undefined, // no CHECK constraint in Prisma Schema :/
            doc: comment ? comment.comments.map(c => c.text).join('\n') : undefined
        }),
        relations: fields.flatMap(f => f.attributes?.filter(a => a.path.value.indexOf('relation') >= 0).flatMap(a => formatRelation(schema, model, f, a)) || [])
    }
}

function buildAttribute(field: FieldDeclaration, comment: CommentBlock | undefined): Attribute {
    const comments = (comment?.comments || []).concat(field.comment ? [field.comment] : [])
    const dbType = field.attributes?.find(a => a.path.value[0] === 'db')
    return removeUndefined({
        name: getAttributeName(field),
        type: (dbType ? formatDbType(dbType) : undefined) || formatPrismaType(field.type),
        null: field.type.kind === 'optional' ? true : undefined,
        default: field.attributes
            ?.find(a => a.path.value.indexOf('default') >= 0)
            ?.args
            ?.map(formatSchemaArgument).join(', ') || undefined,
        doc: comments.length > 0 ? comments.map(c => c.text).join('\n') : undefined
    })
}

function formatConstraint(attr: BlockAttribute): { name?: string, attrs: AttributePath[] } {
    const attrs: AttributePath[] = formatFields(getNamedArgument(attr, 'fields')?.expression || getFirstUnnamedArgument(attr)).map(attr => [attr])
    const name = getNamedArgument(attr, 'name')?.expression
    return removeUndefined({
        name: name ? formatSchemaExpression(name) : undefined,
        attrs
    })
}

function formatRelation(schema: PrismaSchema, model: ModelDeclaration, field: FieldDeclaration, attr: FieldAttribute): Relation[] {
    const srcTableName = getEntityName(model)
    const refModelName = formatPrismaType(field.type)
    const refModel = getModel(schema, refModelName)
    const refTableName = refModel ? getEntityName(refModel) : refModelName
    return zip(
        formatFields(getNamedArgument(attr, 'fields')?.expression),
        formatFields(getNamedArgument(attr, 'references')?.expression)
    ).map(([src, ref]) => {
        const srcField = getField(model, src)
        const srcFieldName = srcField ? getAttributeName(srcField) : src
        const refField = refModel ? getField(refModel, ref) : undefined
        const refFieldName = refField ? getAttributeName(refField) : ref
        return {
            name: `fk_${srcTableName}_${srcFieldName}_${refTableName}_${refFieldName}`,
            src: removeUndefined({schema: getEntitySchema(model) || undefined, entity: srcTableName}),
            ref: removeUndefined({schema: refModel ? getEntitySchema(refModel) || undefined : undefined, entity: refTableName}),
            attrs: [{src: [srcFieldName], ref: [refFieldName]}]
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

function buildEnum(e: EnumDeclaration): Type {
    return {
        name: e.name.value,
        values: e.members.filter((m): m is EnumValue => m.kind === 'enumValue').map(v => v.name.value)
    }
}

function buildType(model: ModelDeclaration): Type {
    return {
        name: model.name.value,
        attrs: model.members.flatMap((member, index, array) => {
            const prev = array[index - 1]
            return member.kind === 'field' ? [buildAttribute(member, prev?.kind === 'commentBlock' ? prev : undefined)] : []
        })
    }
}

function getEntitySchema(model: ModelDeclaration): SchemaName {
    const dbSchema = model.members.find((m): m is BlockAttribute => m.kind === 'blockAttribute' && m.path.value[0] === 'schema')
    return dbSchema ? (dbSchema.args || []).map(formatSchemaArgument).join('_') : ''
}

function getEntityName(model: ModelDeclaration): EntityName {
    const dbName = model.members.find((m): m is BlockAttribute => m.kind === 'blockAttribute' && m.path.value[0] === 'map')
    return dbName ? (dbName.args || []).map(formatSchemaArgument).join('_') : model.name.value
}

function getAttributeName(field: FieldDeclaration): AttributeName {
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
