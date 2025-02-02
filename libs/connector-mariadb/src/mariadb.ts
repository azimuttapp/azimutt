import {
    distinct,
    groupBy,
    isNotUndefined,
    mapEntriesAsync,
    mapValuesAsync,
    pluralizeL,
    removeEmpty,
    removeSurroundingParentheses,
    removeUndefined
} from "@azimutt/utils";
import {
    Attribute,
    AttributeName,
    AttributePath,
    attributeRefToId,
    AttributeValue,
    Check,
    ConnectorSchemaOpts,
    connectorSchemaOptsDefaults,
    Database,
    DatabaseKind,
    Entity,
    EntityId,
    EntityRef,
    entityRefFromId,
    entityRefToId,
    formatConnectorScope,
    handleError,
    Index,
    isPolymorphic,
    PrimaryKey,
    Relation,
    schemaToAttributes,
    ValueSchema,
    valuesToSchema
} from "@azimutt/models";
import {buildSqlColumn, buildSqlTable, scopeWhere} from "./helpers";
import {Conn} from "./connect";

export const getSchema = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<Database> => {
    const start = Date.now()
    const scope = formatConnectorScope({schema: 'schema', entity: 'table'}, opts)
    opts.logger.log(`Connected to the database${scope ? `, exporting for ${scope}` : ''} ...`)

    // access system tables only
    const tables: RawTable[] = await getTables(opts)(conn)
    opts.logger.log(`Found ${pluralizeL(tables, 'table')} ...`)
    const columns: RawColumn[] = await getColumns(opts)(conn)
    opts.logger.log(`Found ${pluralizeL(columns, 'column')} ...`)
    const constraintColumns: RawConstraintColumn[] = await getConstraintColumns(opts)(conn)
    opts.logger.log(`Found ${pluralizeL(constraintColumns, 'constraint column')} ...`)
    const checks: RawCheck[] = await getChecks(opts)(conn)
    opts.logger.log(`Found ${pluralizeL(checks, 'check')} ...`)

    // access table data when options are requested
    const columnsByTable: Record<EntityId, RawColumn[]> = groupByEntity(columns)
    const checksByTable: Record<EntityId, RawCheck[]> = groupByEntity(checks)
    const jsonColumns: Record<EntityId, Record<AttributeName, ValueSchema>> = opts.inferJsonAttributes ? await getJsonColumns(columnsByTable, checksByTable, opts)(conn) : {}
    const polyColumns: Record<EntityId, Record<AttributeName, string[]>> = opts.inferPolymorphicRelations ? await getPolyColumns(columnsByTable, opts)(conn) : {}
    // TODO: pii, join relations...

    // build the database
    const constraintTypes: Record<RawConstraintColumnType, RawConstraintColumn[]> = groupBy(constraintColumns, c => c.constraint_type)
    const primaryKeysByTable: Record<EntityId, RawConstraintColumn[]> = groupBy(constraintTypes['PRIMARY KEY'] || [], toEntityId)
    const uniquesByTable: Record<EntityId, RawConstraintColumn[]> = groupBy(constraintTypes['UNIQUE'] || [], toEntityId)
    const indexesByTable: Record<EntityId, RawConstraintColumn[]> = groupBy(constraintTypes['INDEX'] || [], toEntityId)
    const foreignKeys: RawConstraintColumn[][] = Object.values(groupBy(constraintTypes['FOREIGN KEY'] || [], c => `${c.table_schema}.${c.table_name}.${c.constraint_name}`))
    opts.logger.log(`✔︎ Exported ${pluralizeL(tables, 'table')} and ${pluralizeL(foreignKeys, 'relation')} from the database!`)
    return removeUndefined({
        entities: tables.map(table => [toEntityId(table), table] as const).map(([id, table]) => buildEntity(
            table,
            columnsByTable[id] || [],
            primaryKeysByTable[id] || [],
            uniquesByTable[id] || [],
            indexesByTable[id] || [],
            checksByTable[id] || [],
            jsonColumns[id] || {},
            polyColumns[id] || {},
        )),
        relations: foreignKeys.map(buildRelation),
        types: undefined,
        doc: undefined,
        stats: removeUndefined({
            name: conn.url.db,
            kind: DatabaseKind.Enum.mariadb,
            version: undefined,
            size: undefined,
        }),
        extra: removeUndefined({
            source: `MariaDB connector`,
            createdAt: new Date().toISOString(),
            creationTimeMs: Date.now() - start,
        }),
    })
}

// 👇️ Private functions, some are exported only for tests
// If you use them, beware of breaking changes!

const toEntityId = <T extends { table_schema: string, table_name: string }>(value: T): EntityId => entityRefToId({schema: value.table_schema, entity: value.table_name})
const groupByEntity = <T extends { table_schema: string, table_name: string }>(values: T[]): Record<EntityId, T[]> => groupBy(values, toEntityId)

export type RawTable = {
    table_schema: string
    table_name: string
    table_kind: 'BASE TABLE' | 'VIEW' | 'SYSTEM VIEW'
    table_engine: 'MEMORY' | 'MyISAM' | 'InnoDB' | null
    table_comment: string // default: '' and 'VIEW'
    table_rows: number | bigint | null // null for views
    table_size: number | bigint | null // null for views
    index_size: number | bigint | null // null for views
    row_size: number | null // null for views
    auto_increment_next: number | null
    table_options: string | null // ex: 'max_rows=2802'
    table_created_at: Date | null // null for views
    definition: string | null // for views
}

export const getTables = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawTable[]> => {
    // https://dev.mysql.com/doc/refman/en/information-schema-tables-table.html
    return conn.query<RawTable>(
        `SELECT t.TABLE_SCHEMA    AS table_schema
              , t.TABLE_NAME      AS table_name
              , t.TABLE_TYPE      AS table_kind
              , t.ENGINE          AS table_engine
              , t.TABLE_COMMENT   AS table_comment
              , t.TABLE_ROWS      AS table_rows
              , t.DATA_LENGTH     AS table_size
              , t.INDEX_LENGTH    AS index_size
              , t.AVG_ROW_LENGTH  AS row_size
              , t.AUTO_INCREMENT  AS auto_increment_next
              , t.CREATE_OPTIONS  AS table_options
              , t.CREATE_TIME     AS table_created_at
              , v.VIEW_DEFINITION AS definition
         FROM information_schema.TABLES t
                  LEFT JOIN information_schema.VIEWS v ON v.TABLE_SCHEMA = t.TABLE_SCHEMA AND v.TABLE_NAME = t.TABLE_NAME
         WHERE ${scopeWhere({schema: 't.TABLE_SCHEMA', entity: 't.TABLE_NAME'}, opts)}
         ORDER BY table_schema, table_name;`, [], 'getTables'
    ).catch(handleError(`Failed to get tables`, [], opts))
}

function buildEntity(table: RawTable, columns: RawColumn[], primaryKeyColumns: RawConstraintColumn[], uniqueColumns: RawConstraintColumn[], indexColumns: RawConstraintColumn[], checks: RawCheck[], jsonColumns: Record<AttributeName, ValueSchema>, polyColumns: Record<AttributeName, string[]>): Entity {
    const indexes = Object.values(groupBy(uniqueColumns, c => c.constraint_name))
        .concat(Object.values(groupBy(indexColumns, c => c.constraint_name)))
    return removeEmpty({
        schema: table.table_schema,
        name: table.table_name,
        kind: table.table_kind === 'VIEW' || table.table_kind === 'SYSTEM VIEW' ? 'view' as const : undefined,
        def: table.definition || undefined,
        attrs: columns.slice(0)
            .sort((a, b) => a.column_index > b.column_index ? 1 : a.column_index < b.column_index ? -1 : 0)
            .map(c => buildAttribute(c, jsonColumns[c.column_name], polyColumns[c.column_name])),
        pk: primaryKeyColumns.length > 0 ? buildPrimaryKey(primaryKeyColumns) : undefined,
        indexes: indexes.map(buildIndex),
        checks: checks.map(buildCheck).filter(isNotUndefined),
        doc: table.table_comment === 'VIEW' ? undefined : table.table_comment || undefined,
        stats: removeUndefined({
            rows: asNumber(table.table_rows),
            size: asNumber(table.table_size),
            sizeIdx: asNumber(table.index_size),
            sizeToast: undefined,
            sizeToastIdx: undefined,
            scanSeq: undefined,
            scanSeqLast: undefined,
            scanIdx: undefined,
            scanIdxLast: undefined,
            analyzeLast: undefined,
            vacuumLast: undefined,
        }),
        extra: undefined
    })
}

const asNumber = (i: bigint | number | null): number | undefined => i !== null ? (typeof i === 'bigint' ? Number(i) : i) : undefined

export type RawColumn = {
    table_schema: string
    table_name: string
    column_index: number | bigint
    column_name: string
    column_type: string
    column_nullable: 'YES' | 'NO'
    column_default: string | null
    column_comment: string
    column_extra: string // ex: 'auto_increment', 'on update CURRENT_TIMESTAMP'
}

export const getColumns = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawColumn[]> => {
    // https://dev.mysql.com/doc/refman/en/information-schema-columns-table.html
    return conn.query<RawColumn>(
        `SELECT TABLE_SCHEMA     AS table_schema
              , TABLE_NAME       AS table_name
              , ORDINAL_POSITION AS column_index
              , COLUMN_NAME      AS column_name
              , COLUMN_TYPE      AS column_type
              , IS_NULLABLE      AS column_nullable
              , COLUMN_DEFAULT   AS column_default
              , COLUMN_COMMENT   AS column_comment
              , EXTRA            AS column_extra
         FROM information_schema.COLUMNS
         WHERE ${scopeWhere({schema: 'TABLE_SCHEMA', entity: 'TABLE_NAME'}, opts)}
         ORDER BY table_schema, table_name, column_index;`, [], 'getColumns'
    ).catch(handleError(`Failed to get columns`, [], opts))
}

function buildAttribute(column: RawColumn, jsonColumn: ValueSchema | undefined, values: string[] | undefined): Attribute {
    return removeEmpty({
        name: column.column_name,
        type: column.column_type,
        null: column.column_nullable === 'YES' ? true : undefined,
        gen: undefined,
        default: column.column_default || undefined,
        attrs: jsonColumn ? schemaToAttributes(jsonColumn) : undefined,
        doc: column.column_comment || undefined,
        stats: removeUndefined({
            nulls: undefined,
            bytesAvg: undefined,
            cardinality: undefined,
            commonValues: undefined,
            distinctValues: values,
            histogram: undefined,
            min: undefined,
            max: undefined,
        }),
        extra: undefined
    })
}

export type RawConstraintColumnType = 'PRIMARY KEY' | 'UNIQUE' | 'FOREIGN KEY' | 'INDEX'
export type RawConstraintColumn = {
    constraint_name: string // default: 'PRIMARY'
    constraint_type: RawConstraintColumnType
    table_schema: string
    table_name: string
    column_name: string
    column_index: number | bigint
    ref_schema: string | null
    ref_table: string | null
    ref_column: string | null
}

export const getConstraintColumns = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawConstraintColumn[]> => {
    // https://dev.mysql.com/doc/refman/en/information-schema-key-column-usage-table.html
    // https://dev.mysql.com/doc/refman/en/information-schema-table-constraints-table.html
    // https://dev.mysql.com/doc/refman/en/information-schema-statistics-table.html
    return conn.query<RawConstraintColumn>(
        `SELECT c.CONSTRAINT_NAME          AS constraint_name
              , c.CONSTRAINT_TYPE          AS constraint_type
              , c.TABLE_SCHEMA             AS table_schema
              , c.TABLE_NAME               AS table_name
              , cc.COLUMN_NAME             AS column_name
              , cc.ORDINAL_POSITION        AS column_index
              , cc.REFERENCED_TABLE_SCHEMA AS ref_schema
              , cc.REFERENCED_TABLE_NAME   AS ref_table
              , cc.REFERENCED_COLUMN_NAME  AS ref_column
         FROM information_schema.TABLE_CONSTRAINTS c
                  LEFT JOIN information_schema.KEY_COLUMN_USAGE cc ON cc.CONSTRAINT_CATALOG = c.CONSTRAINT_CATALOG AND cc.CONSTRAINT_SCHEMA = c.CONSTRAINT_SCHEMA AND cc.CONSTRAINT_NAME = c.CONSTRAINT_NAME AND cc.TABLE_NAME = c.TABLE_NAME
         WHERE c.CONSTRAINT_TYPE != 'CHECK' AND ${scopeWhere({schema: 'c.TABLE_SCHEMA', entity: 'c.TABLE_NAME'}, opts)}
         UNION
         SELECT i.INDEX_NAME   AS constraint_name
              , "INDEX"        AS constraint_type
              , i.TABLE_SCHEMA AS table_schema
              , i.TABLE_NAME   AS table_name
              , i.COLUMN_NAME  AS column_name
              , i.SEQ_IN_INDEX AS column_index
              , null           AS ref_schema
              , null           AS ref_table
              , null           AS ref_column
         FROM information_schema.STATISTICS i
                  LEFT JOIN information_schema.TABLE_CONSTRAINTS c ON c.TABLE_SCHEMA = i.TABLE_SCHEMA AND c.TABLE_NAME = i.TABLE_NAME AND c.CONSTRAINT_NAME = i.INDEX_NAME
         WHERE c.CONSTRAINT_TYPE IS NULL
           AND ${scopeWhere({schema: 'i.TABLE_SCHEMA', entity: 'i.TABLE_NAME'}, opts)}
         ORDER BY table_schema, table_name, constraint_name, column_index;`, [], 'getConstraintColumns'
    ).catch(handleError(`Failed to get constraints`, [], opts))
}

function buildPrimaryKey(columns: RawConstraintColumn[]): PrimaryKey {
    const first = columns[0]
    return removeUndefined({
        name: first.constraint_name === 'PRIMARY' ? undefined : first.constraint_name || undefined,
        attrs: columns.slice(0)
            .sort((a, b) => a.column_index > b.column_index ? 1 : a.column_index < b.column_index ? -1 : 0)
            .map(c => [c.column_name]),
        doc: undefined,
        stats: undefined,
        extra: undefined
    })
}

function buildIndex(columns: RawConstraintColumn[]): Index {
    const first = columns[0]
    return removeUndefined({
        name: first.constraint_name || undefined,
        attrs: columns.slice(0)
            .sort((a, b) => a.column_index > b.column_index ? 1 : a.column_index < b.column_index ? -1 : 0)
            .map(c => [c.column_name]),
        unique: first.constraint_type === 'UNIQUE' ? true : undefined, // false when not specified
        partial: undefined,
        definition: undefined,
        doc: undefined,
        stats: undefined,
        extra: undefined
    })
}

function buildRelation(columns: RawConstraintColumn[]): Relation {
    const first = columns[0]
    return removeUndefined({
        name: first.constraint_name || undefined,
        origin: undefined,
        src: { schema: first.table_schema, entity: first.table_name, attrs: columns.map(c => [c.column_name]) },
        ref: { schema: first.ref_schema || '', entity: first.ref_table || '', attrs: columns.map(c => [c.ref_column || '']) },
        polymorphic: undefined,
        doc: undefined,
        extra: undefined
    })
}

export type RawCheck = {
    constraint_name: string
    table_schema: string
    table_name: string
    definition: string | null
}

export const getChecks = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawCheck[]> => {
    return conn.query<RawCheck>(
        `SELECT c.CONSTRAINT_NAME AS constraint_name
              , c.TABLE_SCHEMA    AS table_schema
              , c.TABLE_NAME      AS table_name
              , ch.CHECK_CLAUSE   AS definition
         FROM information_schema.TABLE_CONSTRAINTS c
                  LEFT JOIN information_schema.CHECK_CONSTRAINTS ch ON ch.CONSTRAINT_CATALOG = c.CONSTRAINT_CATALOG AND ch.CONSTRAINT_SCHEMA = c.CONSTRAINT_SCHEMA AND ch.CONSTRAINT_NAME = c.CONSTRAINT_NAME
         WHERE c.CONSTRAINT_TYPE = 'CHECK' AND ${scopeWhere({schema: 'c.TABLE_SCHEMA', entity: 'c.TABLE_NAME'}, opts)}
         ORDER BY table_schema, table_name, constraint_name;`, [], 'getChecks'
    ).catch(handleError(`Failed to get checks`, [], opts))
}

function buildCheck(check: RawCheck): Check | undefined {
    const columns = distinct([...check.definition?.matchAll(/`([^`]+)`/g) || []].map(m => m[1]))
    if (check.definition && columns.length > 0) {
        return {
            name: check.constraint_name,
            attrs: columns.map(c => [c]),
            predicate: removeSurroundingParentheses(check.definition),
            doc: undefined,
            stats: undefined,
            extra: undefined
        }
    } else {
        // unable to extract columns from check, so can't build it :/
        return undefined
    }
}

const getJsonColumns = (columns: Record<EntityId, RawColumn[]>, checksByTable: Record<EntityId, RawCheck[]>, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<Record<EntityId, Record<AttributeName, ValueSchema>>> => {
    opts.logger.log('Inferring JSON columns ...')
    return mapEntriesAsync(columns, (entityId, tableCols) => {
        const ref = entityRefFromId(entityId)
        const checks = checksByTable[entityId] || []
        // MariaDB JSON is made with a `longtext` type and a check constraint
        const jsonCols = tableCols.filter(c => c.column_type === 'longtext' && checks.find(ch => ch.definition === `json_valid(\`${c.column_name}\`)`))
        return mapValuesAsync(Object.fromEntries(jsonCols.map(c => [c.column_name, c.column_name])), c =>
            getSampleValues(ref, [c], opts)(conn).then(valuesToSchema)
        )
    })
}

const getSampleValues = (ref: EntityRef, attribute: AttributePath, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<AttributeValue[]> => {
    const sqlTable = buildSqlTable(ref)
    const sqlColumn = buildSqlColumn(attribute)
    const sampleSize = opts.sampleSize || connectorSchemaOptsDefaults.sampleSize
    return conn.query<{value: AttributeValue}>(`SELECT ${sqlColumn} AS value FROM ${sqlTable} WHERE ${sqlColumn} IS NOT NULL LIMIT ${sampleSize};`, [], 'getSampleValues')
        .then(rows => rows.map(row => row.value))
        .catch(handleError(`Failed to get sample values for '${attributeRefToId({...ref, attribute})}'`, [], opts))
}

const getPolyColumns = (columns: Record<EntityId, RawColumn[]>, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<Record<EntityId, Record<AttributeName, string[]>>> => {
    opts.logger.log('Inferring polymorphic relations ...')
    return mapEntriesAsync(columns, (entityId, tableCols) => {
        const ref = entityRefFromId(entityId)
        const colNames = tableCols.map(c => c.column_name)
        const polyCols = tableCols.filter(c => isPolymorphic(c.column_name, colNames))
        return mapValuesAsync(Object.fromEntries(polyCols.map(c => [c.column_name, c.column_name])), c =>
            getDistinctValues(ref, [c], opts)(conn).then(values => values.filter((v): v is string => typeof v === 'string'))
        )
    })
}

const getDistinctValues = (ref: EntityRef, attribute: AttributePath, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<AttributeValue[]> => {
    const sqlTable = buildSqlTable(ref)
    const sqlColumn = buildSqlColumn(attribute)
    const sampleSize = opts.sampleSize || connectorSchemaOptsDefaults.sampleSize
    return conn.query<{value: AttributeValue}>(`SELECT DISTINCT ${sqlColumn} AS value FROM ${sqlTable} WHERE ${sqlColumn} IS NOT NULL ORDER BY value LIMIT ${sampleSize};`, [], 'getDistinctValues')
        .then(rows => rows.map(row => row.value))
        .catch(handleError(`Failed to get distinct values for '${attributeRefToId({...ref, attribute})}'`, [], opts))
}
