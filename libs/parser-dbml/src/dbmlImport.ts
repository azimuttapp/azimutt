import DbmlDatabase from "@dbml/core/types/model_structure/database";
import DbmlTable from "@dbml/core/types/model_structure/table";
import DbmlField from "@dbml/core/types/model_structure/field";
import DbmlIndex from "@dbml/core/types/model_structure/indexes";
import DbmlRef from "@dbml/core/types/model_structure/ref";
import DbmlEndpoint from "@dbml/core/types/model_structure/endpoint";
import DbmlEnum from "@dbml/core/types/model_structure/enum";
import DbmlTableGroup from "@dbml/core/types/model_structure/tableGroup";
import DbmlSchema from "@dbml/core/types/model_structure/schema";
import {removeEmpty, removeUndefined} from "@azimutt/utils";
import {
    Attribute,
    AttributePath,
    attributePathFromId,
    Database,
    Entity,
    Index,
    PrimaryKey,
    Relation,
    RelationLink,
    SchemaName,
    Type
} from "@azimutt/models";
import packageJson from "../package.json";
import {AttributeExtra, DatabaseExtra, EntityExtra, Group, IndexExtra, RelationExtra, TypeExtra} from "./extra";

export const defaultSchema = 'public'

export function importDatabase(db: DbmlDatabase): Database {
    const extra: DatabaseExtra = removeEmpty({
        source: `DBML parser <${packageJson.version}>`,
        groups: db.schemas.flatMap(s => s.tableGroups.map(importGroup))
    })
    return removeEmpty({
        entities: db.schemas.flatMap(s => s.tables.map(importEntity)),
        relations: db.schemas.flatMap(s => s.refs.map(importRef)),
        types: db.schemas.flatMap(s => s.enums.map(importType)),
        extra
    })
}

function importEntity(table: DbmlTable): Entity {
    const pkIndex: PrimaryKey = table.indexes.filter(i => i.pk).map(i => removeUndefined({name: i.name, attrs: i.columns.map(c => attributePathFromId(c.value))}))[0]
    const pkCols: AttributePath[] = table.fields.filter(f => f.pk).map(f => attributePathFromId(f.name))

    const entityIndexes: Index[] = table.indexes.filter(i => !i.pk).map(importIndex)
    const attributeUniques: Index[] = table.fields.filter(f => f.unique).map(f => ({attrs: [attributePathFromId(f.name)], unique: true}))
    const indexes = attributeUniques.concat(entityIndexes)

    const extra: EntityExtra = removeUndefined({
        alias: table.alias || undefined,
        color: table.headerColor || undefined
    })

    return removeEmpty({
        schema: importSchemaName(table.schema),
        name: table.name,
        kind: undefined,
        def: undefined,
        attrs: table.fields.map(importAttribute),
        pk: pkIndex ? pkIndex : pkCols.length > 0 ? {attrs: pkCols} : undefined,
        indexes: indexes.length > 0 ? indexes : undefined,
        checks: undefined,
        doc: table.note || undefined,
        stats: undefined,
        extra
    })
}

function importAttribute(field: DbmlField): Attribute {
    const extra: AttributeExtra = removeUndefined({
        increment: field.increment || undefined,
        defaultType: field.dbdefault?.type === 'expression' ? 'expression' : undefined
    })
    return removeEmpty({
        name: field.name,
        type: field.type.type_name,
        null: field.not_null === true ? !field.not_null : undefined,
        gen: undefined,
        default: field.dbdefault?.value,
        attrs: undefined,
        doc: field.note || undefined,
        stats: undefined,
        extra
    })
}

function importIndex(index: DbmlIndex): Index {
    const extra: IndexExtra = removeEmpty({
        attrTypes: removeUndefined(index.columns.reduce((acc, v) => ({...acc, [v.value]: v.type === 'expression' ? 'expression' : undefined}), {}))
    })
    return removeEmpty({
        name: index.name,
        attrs: index.columns.map(c => attributePathFromId(c.value)),
        unique: index.unique || undefined,
        definition: index.type || undefined,
        doc: index.note || undefined,
        extra
    })
}

function importRef(relation: DbmlRef): Relation {
    let [src, ref] = relation.endpoints
    switch (src.relation + '-' + ref.relation) {
        case '1-*': [src, ref] = [ref, src]; break
        case '1-1': if (src.fields.some(f => f.pk)) [src, ref] = [ref, src]; break
    }
    const extra: RelationExtra = removeUndefined({
        onDelete: relation.onDelete,
        onUpdate: relation.onUpdate
    })
    return removeEmpty({
        name: relation.name || undefined,
        src: removeUndefined({...importEndpoint(src), cardinality: src.relation === '1' ? '1' as const : undefined}),
        ref: removeUndefined({...importEndpoint(ref), cardinality: ref.relation === '*' ? 'n' as const : undefined}),
        extra
    })
}

function importEndpoint(endpoint: DbmlEndpoint): RelationLink {
    return removeUndefined({schema: endpoint.schemaName || undefined, entity: endpoint.tableName, attrs: endpoint.fieldNames.map(attributePathFromId)})
}

function importType(e: DbmlEnum): Type {
    const extra: TypeExtra = removeEmpty({
        notes: removeUndefined(e.values.reduce((acc, v) => ({...acc, [v.name]: v.note || undefined}), {}))
    })
    return removeUndefined({
        schema: importSchemaName(e.schema),
        name: e.name,
        values: e.values.map(v => v.name),
        doc: e.note || undefined,
        extra
    })
}

function importGroup(group: DbmlTableGroup): Group {
    return removeUndefined({
        schema: importSchemaName(group.schema),
        name: group.name,
        entities: group.tables.map(t => removeUndefined({schema: importSchemaName(t.schema), entity: t.name})),
    })
}

function importSchemaName(schema: DbmlSchema): SchemaName | undefined {
    return schema.name !== defaultSchema ? schema.name : undefined
}
