import {distinctBy, isNever, isNotUndefined, removeEmpty, removeUndefined} from "@azimutt/utils";
import {
    Attribute,
    AttributePath,
    attributePathSame,
    AttributeValue,
    Check,
    Database,
    Entity,
    entityRefSame,
    entityToId,
    entityToRef,
    Index,
    mergeEntity,
    mergePositions,
    mergeType,
    ParserError,
    ParserResult,
    PrimaryKey,
    Relation,
    TokenPosition,
    Type,
    typeRefSame,
    typeToId,
    typeToRef
} from "@azimutt/models";
import packageJson from "../package.json";
import {
    AliasAst,
    AlterTableStatementAst,
    ColumnAst,
    CommentObject,
    CommentOnStatementAst,
    CreateIndexStatementAst,
    CreateMaterializedViewStatementAst,
    CreateTableStatementAst,
    CreateTypeStatementAst,
    CreateViewStatementAst,
    ExpressionAst,
    FromClauseAst,
    FromClauseItemAst,
    FunctionAst,
    IdentifierAst,
    Operator,
    OperatorLeft,
    OperatorRight,
    PostgresAst,
    SelectClauseColumnAst,
    SelectInnerAst,
    StatementAst,
    TableColumnAst,
    TokenInfo
} from "./postgresAst";
import {duplicated} from "./errors";

export function buildPostgresDatabase(ast: PostgresAst, start: number, parsed: number): ParserResult<Database> {
    const db: Database = {entities: [], relations: [], types: []}
    const errors: ParserError[] = []
    ast.statements.forEach((stmt, i) => evolvePostgres(db, errors, i + 1, stmt))
    const done = Date.now()
    const extra = removeEmpty({
        source: `PostgreSQL parser <${packageJson.version}>`,
        createdAt: new Date().toISOString(),
        creationTimeMs: done - start,
        parsingTimeMs: parsed - start,
        formattingTimeMs: done - parsed,
        comments: ast.comments?.map(c => ({line: c.token.position.start.line, comment: c.value})) || [],
    })
    return new ParserResult(removeEmpty({...db, extra}), errors)
}

export function evolvePostgres(db: Database, errors: ParserError[], index: number, stmt: StatementAst): void {
    if (stmt.kind === 'AlterTable') {
        alterTable(index, stmt, db)
    } else if (stmt.kind === 'CommentOn') {
        commentOn(index, stmt, db)
    } else if (stmt.kind === 'CreateIndex') {
        if (!db.entities) db.entities = []
        createIndex(index, stmt, db.entities)
    } else if (stmt.kind === 'CreateMaterializedView') {
        if (!db.entities) db.entities = []
        const entity = createMaterializedView(index, stmt, db.entities)
        addEntity(db.entities, errors, entity, mergePositions([stmt.schema, stmt.name].map(v => v?.token)))
    } else if (stmt.kind === 'CreateTable') {
        if (!db.entities) db.entities = []
        const res = createTable(index, stmt)
        addEntity(db.entities, errors, res.entity, mergePositions([stmt.schema, stmt.name].map(v => v?.token)))
        res.relations.forEach(r => db.relations?.push(r))
    } else if (stmt.kind === 'CreateType') {
        if (!db.types) db.types = []
        const type = createType(index, stmt)
        addType(db.types, errors, type, mergePositions([stmt.schema, stmt.name].map(v => v?.token)))
    } else if (stmt.kind === 'CreateView') {
        if (!db.entities) db.entities = []
        const entity = createView(index, stmt, db.entities)
        addEntity(db.entities, errors, entity, mergePositions([stmt.schema, stmt.name].map(v => v?.token)))
    } else if (stmt.kind === 'AlterSchema') { // nothing
    } else if (stmt.kind === 'AlterSequence') { // nothing
    } else if (stmt.kind === 'Begin') { // nothing
    } else if (stmt.kind === 'Commit') { // nothing
    } else if (stmt.kind === 'CreateExtension') { // nothing
    } else if (stmt.kind === 'CreateFunction') { // nothing
    } else if (stmt.kind === 'CreateTrigger') { // nothing
    } else if (stmt.kind === 'CreateSchema') { // nothing
    } else if (stmt.kind === 'CreateSequence') { // nothing
    } else if (stmt.kind === 'Delete') { // nothing
    } else if (stmt.kind === 'Drop') { // nothing
    } else if (stmt.kind === 'InsertInto') { // nothing
    } else if (stmt.kind === 'Select') { // nothing
    } else if (stmt.kind === 'Set') { // nothing
    } else if (stmt.kind === 'Show') { // nothing
    } else if (stmt.kind === 'Update') { // nothing
    } else {
        isNever(stmt)
    }
}

function addEntity(entities: Entity[], errors: ParserError[], entity: Entity, pos: TokenPosition): void {
    const ref = entityToRef(entity)
    const prevIndex = entities.findIndex(e => entityRefSame(entityToRef(e), ref))
    if (prevIndex !== -1) {
        const prev = entities[prevIndex]
        errors.push(duplicated(`Entity ${entityToId(entity)}`, prev.extra?.line ? prev.extra.line : undefined, pos))
        entities[prevIndex] = mergeEntity(prev, entity)
    } else {
        entities.push(entity)
    }
}

function addType(types: Type[], errors: ParserError[], type: Type, pos: TokenPosition): void {
    const ref = typeToRef(type)
    const prevIndex = types.findIndex(t => typeRefSame(typeToRef(t), ref))
    if (prevIndex !== -1) {
        const prev = types[prevIndex]
        errors.push(duplicated(`Type ${typeToId(type)}`, prev.extra?.line ? prev.extra.line : undefined, pos))
        types[prevIndex] = mergeType(prev, type)
    } else {
        types.push(type)
    }
}

function createTable(index: number, stmt: CreateTableStatementAst): { entity: Entity, relations: Relation[] } {
    const colPk: PrimaryKey[] = stmt.columns?.flatMap(col => col.constraints?.flatMap(c => c.kind === 'PrimaryKey' ? [removeUndefined({attrs: [[col.name.value]], name: c.constraint?.name.value, extra: {line: c.token.position.start.line, statement: index}})] : []) || []) || []
    const tablePk: PrimaryKey[] = stmt.constraints?.flatMap(c => c.kind === 'PrimaryKey' ? [removeUndefined({attrs: c.columns.map(col => [col.value]), name: c.constraint?.name.value, extra: {line: c.token.position.start.line, statement: index}})] : []) || []
    const pk: PrimaryKey[] = colPk.concat(tablePk)
    const colIndexes: Index[] = stmt.columns?.flatMap(col => col.constraints?.flatMap(c => c.kind === 'Unique' ? [removeUndefined({attrs: [[col.name.value]], unique: true, name: c.constraint?.name.value, extra: {line: c.token.position.start.line, statement: index}})] : []) || []) || []
    const tableIndexes: Index[] = stmt.constraints?.flatMap(c => c.kind === 'Unique' ? [removeUndefined({attrs: c.columns.map(col => [col.value]), unique: true, name: c.constraint?.name.value, extra: {line: c.token.position.start.line, statement: index}})] : []) || []
    const indexes: Index[] = colIndexes.concat(tableIndexes)
    const colChecks: Check[] = stmt.columns?.flatMap(col => col.constraints?.flatMap(c => c.kind === 'Check' ? [removeUndefined({attrs: [[col.name.value]], predicate: expressionToString(c.predicate), name: c.constraint?.name.value, extra: {line: c.token.position.start.line, statement: index}})] : []) || []) || []
    const tableChecks: Check[] = stmt.constraints?.flatMap(c => c.kind === 'Check' ? [removeUndefined({attrs: expressionAttrs(c.predicate), predicate: expressionToString(c.predicate), name: c.constraint?.name.value, extra: {line: c.token.position.start.line, statement: index}})] : []) || []
    const checks: Check[] = colChecks.concat(tableChecks)
    const colRels: Relation[] = stmt.columns?.flatMap(col => col.constraints?.flatMap(c => c.kind === 'ForeignKey' ? [removeUndefined({
        name: c.constraint?.name.value,
        src: removeUndefined({schema: stmt.schema?.value, entity: stmt.name.value, attrs: [[col.name.value]]}),
        ref: removeUndefined({schema: c.schema?.value, entity: c.table.value, attrs: [c.column ? [c.column.value] : []]}),
        extra: {line: c.token.position.start.line, statement: index},
    })] : []) || []) || []
    const tableRels: Relation[] = stmt.constraints?.flatMap(c => c.kind === 'ForeignKey' ? [removeUndefined({
        name: c.constraint?.name.value,
        src: removeUndefined({schema: stmt.schema?.value, entity: stmt.name.value, attrs: c.columns.map(col => [col.value])}),
        ref: removeUndefined({schema: c.ref.schema?.value, entity: c.ref.table.value, attrs: c.ref.columns?.map(col => [col.value]) || []}),
        extra: {line: c.token.position.start.line, statement: index},
    })] : []) || []
    const relations: Relation[] = colRels.concat(tableRels)
    return {entity: removeEmpty({
        schema: stmt.schema?.value,
        name: stmt.name.value,
        kind: undefined,
        def: undefined,
        attrs: (stmt.columns || []).map(c => buildTableAttr(index, c, !!pk.find(pk => pk.attrs.some(a => attributePathSame(a, [c.name.value]))))),
        pk: pk.length > 0 ? pk[0] : undefined,
        indexes,
        checks,
        // doc: z.string().optional(), // not defined in CREATE TABLE
        // stats: EntityStats.optional(), // no stats in SQL
        extra: {line: stmt.token.position.start.line, statement: index},
    }), relations}
}

function buildTableAttr(index: number, c: TableColumnAst, notNull?: boolean): Attribute {
    return removeUndefined({
        name: c.name.value,
        type: c.type.name.value,
        null: (c.constraints?.find(c => c.kind === 'Nullable' ? !c.value : false) || notNull) ? undefined : true,
        // gen: z.boolean().optional(), // not handled for now
        default: (c.constraints || []).flatMap(c => c.kind === 'Default' ? [expressionToValue(c.expression)] : [])[0],
        // attrs: z.lazy(() => Attribute.array().optional()), // no nested attrs from SQL
        // doc: z.string().optional(), // not defined in CREATE TABLE
        // stats: AttributeStats.optional(), // no stats in SQL
        extra: {line: c.name.token.position.start.line, statement: index},
    })
}

function createView(index: number, stmt: CreateViewStatementAst, entities: Entity[]): Entity {
    return removeEmpty({
        schema: stmt.schema?.value,
        name: stmt.name.value,
        kind: 'view' as const,
        def: selectInnerToString(stmt.query),
        attrs: buildViewAttrs(index, stmt.query, stmt.columns, entities),
        // pk: PrimaryKey.optional(), // not in VIEW
        // indexes: Index.array().optional(), // not in VIEW
        // checks: Check.array().optional(), // not in VIEW
        // doc: z.string().optional(), // not in VIEW
        // stats: EntityStats.optional(), // no stats in SQL
        extra: {line: stmt.token.position.start.line, statement: index},
    })
}

function createMaterializedView(index: number, stmt: CreateMaterializedViewStatementAst, entities: Entity[]): Entity {
    return removeEmpty({
        schema: stmt.schema?.value,
        name: stmt.name.value,
        kind: 'materialized view' as const,
        def: selectInnerToString(stmt.query),
        attrs: buildViewAttrs(index, stmt.query, stmt.columns, entities),
        // pk: PrimaryKey.optional(), // not in VIEW
        // indexes: Index.array().optional(), // not in VIEW
        // checks: Check.array().optional(), // not in VIEW
        // doc: z.string().optional(), // not in VIEW
        // stats: EntityStats.optional(), // no stats in SQL
        extra: {line: stmt.token.position.start.line, statement: index},
    })
}

function buildViewAttrs(index: number, query: SelectInnerAst, columns: IdentifierAst[] | undefined, entities: Entity[]): Attribute[] {
    const attrs = selectEntities(query, entities).columns.map(c => removeUndefined({
        name: c.name,
        type: c.type || 'unknown',
        // null: z.boolean().optional(), // not in VIEW
        // gen: z.boolean().optional(), // not handled for now
        // default: AttributeValue.optional(), // now in VIEW
        // attrs: z.lazy(() => Attribute.array().optional()), // no nested attrs from SQL
        // doc: z.string().optional(), // not defined in CREATE TABLE
        // stats: AttributeStats.optional(), // no stats in SQL
        extra: {line: c.token.position.start.line, statement: index},
    }))
    return columns ? columns.map(c => attrs.find(a => a.name === c.value) || {name: c.value, type: 'unknown'}) : attrs
}

function createIndex(index: number, stmt: CreateIndexStatementAst, entities: Entity[]): void {
    const entity = entities.find(e => e.schema === stmt.schema?.value && e.name === stmt.table?.value)
    if (entity) {
        if (!entity.indexes) entity.indexes = []
        entity.indexes.push(removeUndefined({
            name: stmt.name?.value,
            attrs: stmt.columns.map(c => {
                if (c.kind === 'Column') {
                    return [c.column.value] // TODO: improve
                }
            }).filter(isNotUndefined),
            unique: stmt.unique ? true : undefined,
            partial: stmt.where ? expressionToString(stmt.where.predicate) : undefined,
            // TODO: definition: z.string().optional(),
            // doc: z.string().optional(),
            // stats: IndexStats.optional(),
            extra: {line: stmt.token.position.start.line, statement: index},
        }))
    }
}

function alterTable(index: number, stmt: AlterTableStatementAst, db: Database): void {
    const entity = db.entities?.find(e => e.schema === stmt.schema?.value && e.name === stmt.table?.value)
    if (entity) {
        stmt.actions.forEach(action => {
            if (action.kind === 'AddColumn') {
                if (!entity.attrs) entity.attrs = []
                const exists = entity.attrs.find(a => a.name === action.column.name.value)
                if (!exists) entity.attrs.push(buildTableAttr(index, action.column))
            } else if (action.kind === 'DropColumn') {
                const attrIndex = entity.attrs?.findIndex(a => a.name === action.column.value)
                if (attrIndex !== undefined && attrIndex !== -1) entity.attrs?.splice(attrIndex, 1)
                // TODO: remove constraints depending on this column
            } else if (action.kind === 'AlterColumn') {
                const attr = entity.attrs?.find(a => a.name === action.column.value)
                if (attr) {
                    const aa = action.action
                    if (aa.kind === 'Default') {
                        attr.default = aa.action.kind === 'Set' && aa.expression ? expressionToValue(aa.expression) : undefined
                    } else if (aa.kind === 'NotNull') {
                        attr.null = aa.action.kind === 'Set' ? undefined : true
                    } else {
                        isNever(aa)
                    }
                }
            } else if (action.kind === 'AddConstraint') {
                const constraint = action.constraint
                if (constraint.kind === 'PrimaryKey') {
                    entity.pk = removeUndefined({name: constraint.constraint?.name.value, attrs: constraint.columns.map(c => [c.value]), extra: {line: stmt.token.position.start.line, statement: index}})
                } else if (constraint.kind === 'Unique') {
                    if (!entity.indexes) entity.indexes = []
                    entity.indexes.push(removeUndefined({
                        name: constraint.constraint?.name.value,
                        attrs: constraint.columns.map(c => [c.value]),
                        unique: true,
                        extra: {line: stmt.token.position.start.line, statement: index},
                    }))
                } else if (constraint.kind === 'Check') {
                    if (!entity.checks) entity.checks = []
                    entity.checks.push(removeUndefined({
                        name: constraint.constraint?.name.value,
                        attrs: expressionAttrs(constraint.predicate),
                        predicate: expressionToString(constraint.predicate),
                        extra: {line: stmt.token.position.start.line, statement: index},
                    }))
                } else if (constraint.kind === 'ForeignKey') {
                    if (!db.relations) db.relations = []
                    db.relations.push(removeUndefined({
                        name: constraint.constraint?.name.value,
                        src: removeUndefined({schema: stmt.schema?.value, entity: stmt.table?.value, attrs: constraint.columns.map(c => [c.value])}),
                        ref: removeUndefined({schema: constraint.ref.schema?.value, entity: constraint.ref.table.value, attrs: constraint.ref.columns?.map(c => [c.value]) || []}),
                        extra: {line: stmt.token.position.start.line, statement: index},
                    }))
                } else {
                    isNever(constraint)
                }
            } else if (action.kind === 'DropConstraint') {
                if (entity.pk?.name === action.constraint.value) entity.pk = undefined
                const idxIndex = entity.indexes?.findIndex(a => a.name === action.constraint.value)
                if (idxIndex !== undefined && idxIndex !== -1) entity.indexes?.splice(idxIndex, 1)
                const chkIndex = entity.checks?.findIndex(c => c.name === action.constraint.value)
                if (chkIndex !== undefined && chkIndex !== -1) entity.checks?.splice(chkIndex, 1)
                const relIndex = db.relations?.findIndex(r => r.name === action.constraint.value && r.src.schema === stmt.schema?.value && r.src.entity === stmt.table?.value)
                if (relIndex !== undefined && relIndex !== -1) db.relations?.splice(relIndex, 1)
                // TODO: also NOT NULL & DEFAULT constraints...
            } else {
                isNever(action)
            }
        })
    }
}

function createType(index: number, stmt: CreateTypeStatementAst): Type {
    return removeUndefined({
        schema: stmt.schema?.value,
        name: stmt.name.value,
        // alias: z.string().optional(), // does not exist in PostgreSQL
        values: stmt.enum?.values.map(v => v.value),
        attrs: stmt.struct?.attrs.map(a => ({
            name: a.name.value,
            type: a.type.name.value,
        })),
        definition: stmt.base ? '(' + stmt.base.map(p => `${p.name.value} = ${expressionToString(p.value)}`).join(', ') + ')' : undefined,
        // doc: z.string().optional(), // not defined in CREATE TYPE
        extra: {line: stmt.token.position.start.line, statement: index},
    })
}

function commentOn(index: number, stmt: CommentOnStatementAst, db: Database): void {
    // TODO: store comment statement? (where?)
    const object: CommentObject = stmt.object.kind
    if (object === 'Column') {
        const entity = db.entities?.find(e => e.schema === stmt.schema?.value && e.name === stmt.parent?.value)
        const attr = entity?.attrs?.find(a => a.name === stmt.entity.value)
        if (attr) attr.doc = stmt.comment.kind === 'String' ? stmt.comment.value : undefined
    } else if (object === 'Constraint') {
        const entity = db.entities?.find(e => e.name === stmt.parent?.value && e.schema === stmt.schema?.value)
        if (entity) {
            if (entity.pk?.name === stmt.entity.value) entity.pk.doc = stmt.comment.kind === 'String' ? stmt.comment.value : undefined
            const index = entity.indexes?.find(i => i.name === stmt.entity.value)
            if (index) index.doc = stmt.comment.kind === 'String' ? stmt.comment.value : undefined
            const check = entity.checks?.find(c => c.name === stmt.entity.value)
            if (check) check.doc = stmt.comment.kind === 'String' ? stmt.comment.value : undefined
        }
        const rel = db.relations?.find(r => r.name === stmt.entity.value && r.src.entity === stmt.parent?.value && r.src.schema === stmt.schema?.value)
        if (rel) rel.doc = stmt.comment.kind === 'String' ? stmt.comment.value : undefined
    } else if (object === 'Database') {
        if (!db.extra) db.extra = {}
        db.extra.doc = stmt.comment.kind === 'String' ? stmt.comment.value : undefined
    } else if (object === 'Extension') {
        // not stored
    } else if (object === 'Index') {
        const index = db.entities?.flatMap(e => e.schema === stmt.schema?.value && e.name === stmt.parent?.value ? e.indexes?.filter(i => i.name === stmt.entity.value) : [])?.[0]
        if (index) index.doc = stmt.comment.kind === 'String' ? stmt.comment.value : undefined
    } else if (object === 'Schema') {
        // not stored
    } else if (object === 'Table' || object === 'View' || object === 'MaterializedView') {
        const entity = db.entities?.find(e => e.schema === stmt.schema?.value && e.name === stmt.entity.value)
        if (entity) entity.doc = stmt.comment.kind === 'String' ? stmt.comment.value : undefined
    } else if (object === 'Type') {
        const type = db.types?.find(e => e.schema === stmt.schema?.value && e.name === stmt.entity.value)
        if (type) type.doc = stmt.comment.kind === 'String' ? stmt.comment.value : undefined
    } else {
        isNever(object)
    }
}

function selectInnerToString(s: SelectInnerAst): string {
    const select = 'SELECT ' + s.columns.map(c => expressionToString(c) + (c.alias ? ' ' + aliasToString(c.alias) : '')).join(', ')
    const from = s.from ? fromToString(s.from) : ''
    const where = s.where ? ' WHERE ' + expressionToString(s.where.predicate) : ''
    return select + from + where
}

function fromToString(f: FromClauseAst): string {
    if (f.kind === 'Table') return ' FROM ' + (f.schema ? f.schema.value + '.' : '') + f.table.value + (f.alias ? ' ' + aliasToString(f.alias) : '')
    if (f.kind === 'Select') return ' FROM (' + selectInnerToString(f.select) + ')' + (f.alias ? ' ' + aliasToString(f.alias) : '')
    return isNever(f)
}

function aliasToString(a: AliasAst): string {
    return (a.token ? 'AS ' : '') + a.name.value
}

function expressionToString(e: ExpressionAst): string {
    if (e.kind === 'String') return "'" + e.value + "'"
    if (e.kind === 'Integer') return e.value.toString()
    if (e.kind === 'Decimal') return e.value.toString()
    if (e.kind === 'Boolean') return e.value.toString()
    if (e.kind === 'Null') return 'null'
    if (e.kind === 'Parameter') return e.value
    if (e.kind === 'Column') return columnToString(e)
    if (e.kind === 'Wildcard') return (e.schema ? e.schema.value + '.' : '') + (e.table ? e.table.value + '.' : '') + '*'
    if (e.kind === 'Function') return functionToString(e)
    if (e.kind === 'Group') return '(' + expressionToString(e.expression) + ')'
    if (e.kind === 'Operation') return expressionToString(e.left) + ' ' + operatorToString(e.op.kind) + ' ' + expressionToString(e.right)
    if (e.kind === 'OperationLeft') return operatorLeftToString(e.op.kind) + ' ' + expressionToString(e.right)
    if (e.kind === 'OperationRight') return expressionToString(e.left) + ' ' + operatorRightToString(e.op.kind)
    if (e.kind === 'Array') return '[' + e.items.map(expressionToString).join(', ') + ']'
    if (e.kind === 'List') return '(' + e.items.map(expressionToString).join(', ') + ')'
    return isNever(e)
}

function expressionToValue(e: ExpressionAst): AttributeValue {
    if (e.kind === 'String') return e.value
    if (e.kind === 'Integer') return e.value
    if (e.kind === 'Decimal') return e.value
    if (e.kind === 'Boolean') return e.value
    if (e.kind === 'Null') return null
    if (e.kind === 'Parameter') return e.value
    if (e.kind === 'Column') return columnToString(e)
    if (e.kind === 'Wildcard') return (e.schema ? e.schema.value + '.' : '') + (e.table ? e.table.value + '.' : '') + '*'
    if (e.kind === 'Function') return '`' + functionToString(e) + '`'
    if (e.kind === 'Group') return expressionToValue(e.expression)
    if (e.kind === 'Operation') return '`' + expressionToString(e) + '`'
    if (e.kind === 'OperationLeft') return '`' + expressionToString(e) + '`'
    if (e.kind === 'OperationRight') return '`' + expressionToString(e) + '`'
    if (e.kind === 'Array') return e.items.map(expressionToValue)
    if (e.kind === 'List') return e.items.map(expressionToValue)
    return isNever(e)
}

function columnToString(c: ColumnAst): string {
    const schema = c.schema ? c.schema.value + '.' : ''
    const table = c.table ? c.table.value + '.' : ''
    const json = c.json ? c.json.map(j => j.kind + j.field.value).join('') : ''
    return schema + table + c.column.value + json
}

function functionToString(f: FunctionAst): string {
    const schema = f.schema ? f.schema.value + '.' : ''
    const distinct = f.distinct ? 'distinct ' : ''
    const params = f.parameters.map(expressionToString).join(', ')
    return schema + f.function.value + '(' + distinct + params + ')'
}

function operatorToString(o: Operator): string {
    if (o === 'Or') return 'OR'
    if (o === 'And') return 'AND'
    if (o === 'Is') return 'IS'
    if (o === 'In') return 'IN'
    if (o === 'NotIn') return 'NOT IN'
    if (o === 'Like') return 'LIKE'
    if (o === 'NotLike') return 'NOT LIKE'
    return o
}

function operatorLeftToString(o: OperatorLeft): string {
    if (o === 'Not') return 'NOT'
    if (o === 'Interval') return 'INTERVAL'
    return o
}

function operatorRightToString(o: OperatorRight): string {
    if (o === 'IsNull') return 'IS NULL'
    if (o === 'NotNull') return 'IS NOT NULL'
    return o
}

function expressionAttrs(e: ExpressionAst): AttributePath[] {
    if (e.kind === 'String') return []
    if (e.kind === 'Integer') return []
    if (e.kind === 'Decimal') return []
    if (e.kind === 'Boolean') return []
    if (e.kind === 'Null') return []
    if (e.kind === 'Parameter') return []
    if (e.kind === 'Column') return [[e.column.value]]
    if (e.kind === 'Wildcard') return []
    if (e.kind === 'Function') return distinctBy(e.parameters.flatMap(expressionAttrs), p => p.join('.'))
    if (e.kind === 'Group') return expressionAttrs(e.expression)
    if (e.kind === 'Operation') return distinctBy(expressionAttrs(e.left).concat(expressionAttrs(e.right)), p => p.join('.'))
    if (e.kind === 'OperationLeft') return expressionAttrs(e.right)
    if (e.kind === 'OperationRight') return expressionAttrs(e.left)
    if (e.kind === 'Array') return []
    if (e.kind === 'List') return []
    return isNever(e)
}

export type SelectEntities = { columns: SelectColumn[], sources: SelectSource[] }
export type SelectColumn = { schema?: string, table?: string, name: string, type?: string, sources: SelectColumnSource[], token: TokenInfo }
export type SelectColumnSource = { schema?: string, table: string, column: string, type?: string }
export type SelectSource = { name: string, from: SelectSourceFrom }
export type SelectSourceFrom = SelectSourceTable | SelectSourceSelect
export type SelectSourceTable = { kind: 'Table', schema?: string, table: string, columns?: { name: string, type: string }[] }
export type SelectSourceSelect = { kind: 'Select' } & SelectEntities

// TODO: also extract entities in clauses such as WHERE, HAVING... (know all use involved tables & columns, wherever they are used)
export function selectEntities(s: SelectInnerAst, entities: Entity[]): SelectEntities {
    const sources = s.from ? selectTables(s.from, entities) : []
    const columns: SelectColumn[] = s.columns.flatMap((c, i) => selectColumn(c, i, sources))
    return {columns, sources}
}
function selectTables(f: FromClauseAst, entities: Entity[]): SelectSource[] {
    const joins = f.joins?.map(j => fromTables(j.from, entities)) || []
    return [fromTables(f, entities), ...joins]
}
function fromTables(i: FromClauseItemAst, entities: Entity[]): SelectSource {
    if (i.kind === 'Table') {
        const entity = findEntity(entities, i.table.value, i.schema?.value)
        if (entity) {
            return {name: i.alias?.name.value || i.table.value, from: removeEmpty({kind: 'Table' as const, schema: entity.schema, table: entity.name, columns: entity.attrs?.map(a => ({name: a.name, type: a.type})) || []})}
        } else {
            return {name: i.alias?.name.value || i.table.value, from: removeUndefined({kind: 'Table' as const, schema: i.schema?.value, table: i.table.value})}
        }
    } else if (i.kind === 'Select') {
        return {name: i.alias?.name.value || '', from: {kind: 'Select', ...selectEntities(i.select, entities)}}
    } else {
        return isNever(i)
    }
}
function selectColumn(c: SelectClauseColumnAst, i: number, sources: SelectSource[]): SelectColumn[] {
    if(c.kind === 'Column') {
        const ref = removeUndefined({schema: c.schema?.value, table: c.table?.value, name: c.alias ? c.alias.name.value : c.column.value, token: c.column.token})
        const source = findSource(sources, c.schema?.value, c.table?.value, c.column.value)?.from
        if (source?.kind === 'Table') {
            const col = source.columns?.find(col => col.name === c.column.value)
            return [removeUndefined({...ref, type: col?.type, sources: [removeUndefined({schema: source.schema, table: source.table, column: c.column.value, type: col?.type})]})]
        } else if (source?.kind === 'Select') {
            const col = source.columns.find(col => col.name === c.column.value)
            return [col ? col : {...ref, sources: []}] // `col` should always exist in correct queries
        } else {
            return [{...ref, sources: []}] // `source` should always exist in correct queries
        }
    } else if (c.kind === 'Wildcard') {
        const ref = removeUndefined({schema: c.schema?.value, table: c.table?.value, name: c.alias ? c.alias.name.value : '*', token: c.token})
        const source = findSource(sources, c.schema?.value, c.table?.value, undefined)?.from
        if (source?.kind === 'Table') {
            const cols = source.columns || []
            if(cols.length > 0) {
                return cols.map(a => ({...ref, name: a.name, type: a.type, sources: [removeUndefined({schema: source.schema, table: source.table, column: a.name, type: a.type})]}))
            } else {
                return [{...ref, sources: []}] // Wildcard from a table with no columns :/ (happen when missing entities)
            }
        } else if (source?.kind === 'Select') {
            return source.columns.map(col => removeUndefined({...col, schema: c.schema?.value, table: c.table?.value}))
        } else {
            return [{...ref, sources: []}] // `source` should always exist in correct queries
        }
    } else if (c.kind === 'Function') {
        return [{name: c.alias ? c.alias.name.value : c.function.value, sources: columnSources(c, sources), token: c.function.token}]
    } else {
        return [{name: c.alias ? c.alias.name.value : `col_${i + 1}`, sources: columnSources(c, sources), token: expressionToken(c)}]
    }
}
function findEntity(entities: Entity[], entity: string, schema: string | undefined): Entity | undefined {
    const candidates = entities.filter(e => e.name === entity)
    if (schema !== undefined) return candidates.find(e => e.schema === schema)
    if (candidates.length === 1) return candidates[0]
    return candidates.find(e => e.schema === undefined) || candidates.find(e => e.schema === '')
}
function findSource(sources: SelectSource[], schema: string | undefined, table: string | undefined, column: string | undefined): SelectSource | undefined {
    // not sure what to do with `schema` :/
    if (table) {
        return sources.find(s => s.name === table)
    }
    if (column) {
        const candidates = sources.filter(s => {
            if (s.from.kind === 'Table') {
                return !!s.from.columns?.find(a => a.name === column)
            } else if (s.from.kind === 'Select') {
                return !!s.from.columns.find(c => c.name === column)
            } else {
                return isNever(s.from)
            }
        })
        return candidates.length === 1 ? candidates[0] : sources.length === 1 ? sources[0] : undefined
    }
    return sources.length === 1 ? sources[0] : undefined
}
function columnSources(c: ExpressionAst, sources: SelectSource[]): SelectColumnSource[] {
    if (c.kind === 'Column') {
        const source = c.table ? sources.find(s => s.name === c.table?.value) : sources.length === 1 ? sources[0] : undefined
        if (source && source.from.kind === 'Table') {
            return [removeUndefined({schema: source.from.schema, table: source.from.table, column: c.column.value})]
        }
    }
    if (c.kind === 'Wildcard') return []
    if (c.kind === 'Function') return c.parameters.flatMap(p => columnSources(p, sources))
    if (c.kind === 'Group') return columnSources(c.expression, sources)
    if (c.kind === 'Operation') return columnSources(c.left, sources).concat(columnSources(c.right, sources))
    if (c.kind === 'OperationLeft') return columnSources(c.right, sources)
    if (c.kind === 'OperationRight') return columnSources(c.left, sources)
    return []
}
function expressionToken(e: ExpressionAst): TokenPosition {
    if (e.kind === 'Parameter' || e.kind === 'String' || e.kind === 'Decimal' || e.kind === 'Integer' || e.kind === 'Boolean' || e.kind === 'Null') {
        return e.token
    } else if (e.kind === 'Column') {
        return e.column.token
    } else if (e.kind === 'Wildcard') {
        return e.token
    } else if (e.kind === 'Function') {
        return e.function.token
    } else if (e.kind === 'Group') {
        return expressionToken(e.expression)
    } else if (e.kind === 'Operation') {
        return mergePositions([expressionToken(e.left), expressionToken(e.right)])
    } else if (e.kind === 'OperationLeft') {
        return mergePositions([e.op.token, expressionToken(e.right)])
    } else if (e.kind === 'OperationRight') {
        return mergePositions([expressionToken(e.left), e.op.token])
    } else if (e.kind === 'Array') {
        return mergePositions([e.token, ...e.items.map(expressionToken)])
    } else if (e.kind === 'List') {
        return mergePositions(e.items.map(expressionToken))
    } else {
        return isNever(e)
    }
}
