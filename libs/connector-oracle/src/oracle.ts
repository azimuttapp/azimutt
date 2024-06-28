import {
  groupBy,
  mapEntriesAsync,
  mapValues,
  mapValuesAsync,
  pluralizeL,
  removeEmpty,
  removeUndefined,
} from "@azimutt/utils"
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
  Type,
  ValueSchema,
  valuesToSchema,
} from "@azimutt/models"
import { buildSqlColumn, buildSqlTable } from "./helpers"
import { Conn } from "./connect"

export const getSchema =
  (opts: ConnectorSchemaOpts) =>
  async (conn: Conn): Promise<Database> => {
    const start = Date.now()
    const scope = formatConnectorScope(
      { schema: "schema", entity: "table" },
      opts
    )
    opts.logger.log(
      `Connected to the database${scope ? `, exporting for ${scope}` : ""} ...`
    )

    // access system tables only
    const blockSize: number = await getBlockSize(opts)(conn)
    const database: RawDatabase = await getDatabase(opts)(conn)
    const tables: RawTable[] = await getTables(opts)(conn)
    opts.logger.log(`Found ${pluralizeL(tables, "table")} ...`)
    const columns: RawColumn[] = await getColumns(opts)(conn)
    opts.logger.log(`Found ${pluralizeL(columns, "column")} ...`)
    const constraints: RawConstraint[] = await getConstraints(opts)(conn)
    opts.logger.log(`Found ${pluralizeL(constraints, "constraint")} ...`)
    const indexes: RawIndex[] = await getIndexes(opts)(conn)
    opts.logger.log(`Found ${pluralizeL(indexes, "index")} ...`)
    const relations: RawRelation[] = await getRelations(opts)(conn)
    opts.logger.log(`Found ${pluralizeL(relations, "relation")} ...`)
    const types: RawType[] = await getTypes(opts)(conn)
    opts.logger.log(`Found ${pluralizeL(types, "type")} ...`)

    // access table data when options are requested
    const columnsByTable = groupByEntity(columns)
    const jsonColumns: Record<
      EntityId,
      Record<AttributeName, ValueSchema>
    > = opts.inferJsonAttributes
      ? await getJsonColumns(columnsByTable, opts)(conn)
      : {}
    const polyColumns: Record<
      EntityId,
      Record<AttributeName, string[]>
    > = opts.inferPolymorphicRelations
      ? await getPolyColumns(columnsByTable, opts)(conn)
      : {}
    // TODO: pii, join relations...

    // build the database
    const columnsByIndex: Record<EntityId, { [i: number]: string }> = mapValues(
      columnsByTable,
      (cols) =>
        cols.reduce(
          (acc, col) => ({ ...acc, [col.column_index]: col.column_name }),
          {}
        )
    )
    const constraintsByTable = groupByEntity(constraints)
    const indexesByTable = groupByEntity(indexes)
    opts.logger.log(
      `✔︎ Exported ${pluralizeL(tables, "table")}, ${pluralizeL(relations, "relation")} and ${pluralizeL(types, "type")} from the database!`
    )
    return removeUndefined({
      entities: tables
        .map((table) => [toEntityId(table), table] as const)
        .map(([id, table]) =>
          buildEntity(
            blockSize,
            table,
            columnsByTable[id] || [],
            columnsByIndex[id] || {},
            constraintsByTable[id] || [],
            indexesByTable[id] || [],
            jsonColumns[id] || {},
            polyColumns[id] || {}
          )
        ),
      relations: relations
        .map((r) => buildRelation(r, columnsByIndex))
        .filter((rel): rel is Relation => !!rel),
      types: types.map(buildType),
      doc: undefined,
      stats: removeUndefined({
        name: conn.url.db || database.database,
        kind: DatabaseKind.Enum.postgres,
        version: database.version,
        doc: undefined,
        extractedAt: new Date().toISOString(),
        extractionDuration: Date.now() - start,
        size: database.blks_read * blockSize,
      }),
      extra: undefined,
    })
  }

// 👇️ Private functions, some are exported only for tests
// If you use them, beware of breaking changes!

const toEntityId = <T extends { table_schema: string; table_name: string }>(
  value: T
): EntityId =>
  entityRefToId({ schema: value.table_schema, entity: value.table_name })
const groupByEntity = <T extends { table_schema: string; table_name: string }>(
  values: T[]
): Record<EntityId, T[]> => groupBy(values, toEntityId)

export type RawDatabase = {
  version: string
  database: string
  blks_read: number
}

export const getDatabase =
  (opts: ConnectorSchemaOpts) =>
  async (conn: Conn): Promise<RawDatabase> => {
    const data: RawDatabase = {
      version: "",
      database: "",
      blks_read: 0,
    }

    await conn.query(`SELECT BANNER FROM V$VERSION`).then((res) => {
      data.version = res?.[0]?.[0] as string
    })

    await conn.query(`select name from v$database`).then((res) => {
      data.database = res?.[0]?.[0] as string
    })

    await conn
      .query(`select value from v$sysstat where name = 'physical reads'`)
      .then((res) => {
        data.blks_read = res?.[0]?.[0] ? Number(res[0][0]) : 0
      })

    return data
  }

export const getBlockSize =
  (opts: ConnectorSchemaOpts) =>
  async (conn: Conn): Promise<number> => {
    return conn
      .query(
        `select distinct bytes/blocks AS block_size from user_segments`,
        [],
        "getBlockSize"
      )
      .then((res) => (res?.[0]?.[0] ? Number(res[0][0]) : 8192))
      .catch(handleError(`Failed to get block size`, 0, opts))
  }

export type RawTable = {
  table_schema: string
  table_name: string
}

export const getTables =
  (opts: ConnectorSchemaOpts) =>
  async (conn: Conn): Promise<RawTable[]> => {
    return conn
      .query(`SELECT owner as table_schema, table_name from ALL_ALL_TABLES`)
      .then((res) =>
        res.reduce<RawTable[]>((acc, row) => {
          const [table_schema, table_name] = row as string[]
          acc.push({ table_schema, table_name })
          return acc
        }, [])
      )
      .catch(handleError(`Failed to get tables`, [], opts))
  }

function buildEntity(
  blockSize: number,
  table: RawTable,
  columns: RawColumn[],
  columnsByIndex: { [i: number]: string },
  constraints: RawConstraint[],
  indexes: RawIndex[],
  jsonColumns: Record<AttributeName, ValueSchema>,
  polyColumns: Record<AttributeName, string[]>
): Entity {
  return {
    schema: table.table_schema,
    name: table.table_name,

    attrs:
      columns
        ?.slice(0)
        ?.sort((a, b) => a.column_index - b.column_index)
        ?.map((c) => buildAttribute(c, jsonColumns[c.column_name])) ?? [],
    pk:
      constraints
        .filter((c) => c.constraint_type === "P")
        .map((c) => buildPrimaryKey(c, columnsByIndex))[0] || undefined,
    indexes: indexes.map((i) => buildIndex(blockSize, i, columnsByIndex)),
    checks: constraints
      .filter((c) => c.constraint_type === "C")
      .map((c) => buildCheck(c, columnsByIndex)),
    extra: undefined,
  }
}

export type RawColumn = {
  column_index: number
  table_schema: string
  table_name: string
  column_name: string
  column_type: string
  column_type_len: number
  column_nullable: boolean
}

export const getColumns =
  (opts: ConnectorSchemaOpts) =>
  async (conn: Conn): Promise<RawColumn[]> => {
    return conn
      .query(
        `select column_id, 
                owner as schema_name,
                table_name, 
                column_name, 
                data_type, 
                data_length, 
                nullable
        from sys.dba_tab_columns`,
        [],
        "getColumns"
      )
      .then((res) =>
        res.reduce<RawColumn[]>((acc, row) => {
          const [
            column_index,
            table_schema,
            table_name,
            column_name,
            column_type,
            column_type_len,
            column_nullable,
          ] = row as any[]
          acc.push({
            column_index,
            table_schema,
            table_name,
            column_name,
            column_type,
            column_type_len,
            column_nullable: column_nullable === "Y",
          })
          return acc
        }, [])
      )
      .catch(handleError(`Failed to get columns`, [], opts))
  }

function buildAttribute(
  c: RawColumn,
  jsonColumn: ValueSchema | undefined
): Attribute {
  return removeEmpty({
    name: c.column_name,
    type: c.column_type,
    null: c.column_nullable || undefined,
    attrs: jsonColumn ? schemaToAttributes(jsonColumn) : undefined,
  })
}

type RawConstraint = {
  table_schema: string
  table_name: string
  column_name: string
  constraint_name: string
  constraint_type: "P" | "C" // P: primary key, C: Check,
  deferrable: boolean
}

export const getConstraints =
  (opts: ConnectorSchemaOpts) =>
  async (conn: Conn): Promise<RawConstraint[]> => {
    // https://docs.oracle.com/en/database/oracle/oracle-database/21/refrn/ALL_CONSTRAINTS.html
    // `constraint_type IN ('P', 'C')`: get only primary key and check constraints
    return conn
      .query(
        `SELECT uc.owner AS table_schema,
                uc.table_name,
                acc.COLUMN_NAME, 
                uc.constraint_name, 
                uc.constraint_type,
                uc.DEFERRABLE
        FROM user_constraints uc JOIN all_cons_columns acc ON uc.CONSTRAINT_NAME  = acc.CONSTRAINT_NAME
        WHERE constraint_type IN ('P', 'C')
        ORDER BY table_schema, table_name, constraint_name`,
        [],
        "getConstraints"
      )
      .then((res) =>
        res.reduce<RawConstraint[]>((acc, row) => {
          const [
            table_schema,
            table_name,
            column_name,
            constraint_name,
            constraint_type,
            deferrable,
          ] = row as any[]

          acc.push({
            table_schema,
            table_name,
            column_name,
            constraint_name,
            constraint_type,
            deferrable: deferrable !== "NOT DEFFERRABLE",
          })
          return acc
        }, [])
      )
      .catch(handleError(`Failed to get constraints`, [], opts))
  }

function buildPrimaryKey(
  c: RawConstraint,
  columns: { [i: number]: string }
): PrimaryKey {
  return removeUndefined({
    name: c.constraint_name,
    attrs: [[c.column_name]],
  })
}

function buildCheck(c: RawConstraint, columns: { [i: number]: string }): Check {
  return removeUndefined({
    name: c.constraint_name,
    attrs: [[c.column_name]],
    predicate: "",
  })
}

type RawIndex = {
  table_schema: string
  table_name: string
  index_name: string
  columns: string[]
  is_unique: boolean
}

export const getIndexes =
  (opts: ConnectorSchemaOpts) =>
  async (conn: Conn): Promise<RawIndex[]> => {
    return conn
      .query(
        `SELECT idx.table_owner AS table_schema,
                idx.table_name,
                idx.index_name,
                LISTAGG(col.column_name, ', ') WITHIN GROUP (ORDER BY col.column_position) AS columns,
                CASE
                    WHEN idx.uniqueness = 'UNIQUE' THEN 1
                    ELSE 0
                END AS is_unique
        FROM all_indexes idx
        JOIN all_ind_columns col
        ON 
            idx.index_name = col.index_name
            AND idx.table_owner = col.table_owner
            AND idx.table_name = col.table_name
        GROUP BY 
            idx.index_name, idx.table_owner, idx.table_name, idx.uniqueness`
      )
      .then((res) =>
        res.reduce<RawIndex[]>((acc, row) => {
          const [table_schema, table_name, index_name, columns, is_unique] =
            row as any

          acc.push({
            table_schema,
            table_name,
            index_name,
            columns: columns.split(", "),
            is_unique: Boolean(is_unique),
          })
          return acc
        }, [])
      )
      .catch(handleError(`Failed to get indexes`, [], opts))
  }

function buildIndex(
  blockSize: number,
  index: RawIndex,
  columns: { [i: number]: string }
): Index {
  return removeUndefined({
    name: index.index_name,
    attrs: [index.columns],
    unique: index.is_unique || undefined,
  })
}

type RawRelation = {
  constraint_name: string
  table_schema: string
  table_name: string
  table_column: string
  target_schema: string
  target_table: string
  target_column: string
  is_deferrable: boolean
  on_delete: string
}

export const getRelations =
  (opts: ConnectorSchemaOpts) =>
  async (conn: Conn): Promise<RawRelation[]> => {
    return conn
      .query(
        `
        SELECT
            a.constraint_name,
            a.owner AS table_schema,
            a.table_name AS table_name,
            ac.column_name AS table_column,
            cc.owner AS target_schema,
            cc.table_name AS target_table,
            cc.column_name AS target_column,
            CASE
                WHEN a.deferrable = 'DEFERRABLE' THEN 1
                ELSE 0
            END AS is_deferable,
            a.delete_rule AS on_delete_action
        FROM 
            all_constraints a
        JOIN 
            all_cons_columns ac ON a.constraint_name = ac.constraint_name AND a.owner = ac.owner
        JOIN 
            all_constraints c ON a.r_constraint_name = c.constraint_name AND a.r_owner = c.owner
        JOIN 
            all_cons_columns cc ON c.constraint_name = cc.constraint_name AND c.owner = cc.owner AND ac.position = cc.position
        WHERE 
            a.constraint_type = 'R'
        ORDER BY 
            a.table_name, a.constraint_name, ac.position`,
        [],
        "getRelations"
      )
      .then((res) =>
        res.reduce<RawRelation[]>((acc, row) => {
          const [
            constraint_name,
            table_schema,
            table_name,
            table_column,
            target_schema,
            target_table,
            target_column,
            is_deferrable,
            on_delete,
          ] = row as any[]

          acc.push({
            constraint_name,
            table_schema,
            table_name,
            table_column,
            target_schema,
            target_table,
            target_column,
            is_deferrable: Boolean(is_deferrable),
            on_delete,
          })
          return acc
        }, [])
      )
      .catch(handleError(`Failed to get relations`, [], opts))
  }

function buildRelation(
  r: RawRelation,
  columnsByIndex: Record<EntityId, { [i: number]: string }>
): Relation | undefined {
  const src = { schema: r.table_schema, entity: r.table_name }
  const ref = { schema: r.target_schema, entity: r.target_table }
  const rel: Relation = {
    name: r.constraint_name,
    kind: undefined, // 'many-to-one' when not specified
    origin: undefined, // 'fk' when not specified
    src,
    ref,
    attrs: [
      {
        src: [r.table_column],
        ref: [r.target_column],
      },
    ],
  }
  // don't keep relation if columns are not found :/
  // should not happen if errors are not skipped
  return rel.attrs.length > 0 ? removeUndefined(rel) : undefined
}

export type RawType = {
  type_schema: string
  type_name: string
}

export const getTypes =
  (opts: ConnectorSchemaOpts) =>
  async (conn: Conn): Promise<RawType[]> => {
    return conn
      .query(
        `
        SELECT
            t.owner AS type_schema,
            t.type_name
        FROM
            all_types t
        WHERE t.owner IS NOT NULL
        ORDER BY type_schema, type_name`,
        [],
        "getTypes"
      )
      .then((res) =>
        res.reduce<RawType[]>((acc, row) => {
          const [type_schema, type_name] = row as string[]
          acc.push({ type_schema, type_name })
          return acc
        }, [])
      )
      .catch(handleError(`Failed to get types`, [], opts))
  }

function buildType(t: RawType): Type {
  return removeUndefined({
    schema: t.type_schema,
    name: t.type_name,
  })
}

const getJsonColumns =
  (columns: Record<EntityId, RawColumn[]>, opts: ConnectorSchemaOpts) =>
  async (
    conn: Conn
  ): Promise<Record<EntityId, Record<AttributeName, ValueSchema>>> => {
    opts.logger.log("Inferring JSON columns ...")
    return mapEntriesAsync(columns, (entityId, tableCols) => {
      const ref = entityRefFromId(entityId)
      const jsonCols = tableCols.filter((c) => c.column_type === "jsonb")
      return mapValuesAsync(
        Object.fromEntries(jsonCols.map((c) => [c.column_name, c.column_name])),
        (c) => getSampleValues(ref, [c], opts)(conn).then(valuesToSchema)
      )
    })
  }

const getSampleValues =
  (ref: EntityRef, attribute: AttributePath, opts: ConnectorSchemaOpts) =>
  async (conn: Conn): Promise<AttributeValue[]> => {
    const sqlTable = buildSqlTable(ref)
    const sqlColumn = buildSqlColumn(attribute)
    const sampleSize = opts.sampleSize || connectorSchemaOptsDefaults.sampleSize
    return conn
      .query(
        `SELECT ${sqlColumn} AS value FROM ${sqlTable} WHERE ${sqlColumn} IS NOT NULL FETCH FIRST ${sampleSize} ROWS ONLY`,
        [],
        "getSampleValues"
      )
      .then((rows) =>
        rows.reduce<{ value: AttributeValue }[]>((acc, row) => {
          const [value] = row as any[]
          acc.push({ value })
          return acc
        }, [])
      )
      .catch(
        handleError(
          `Failed to get sample values for '${attributeRefToId({ ...ref, attribute })}'`,
          [],
          opts
        )
      )
  }

const getPolyColumns =
  (columns: Record<EntityId, RawColumn[]>, opts: ConnectorSchemaOpts) =>
  async (
    conn: Conn
  ): Promise<Record<EntityId, Record<AttributeName, string[]>>> => {
    opts.logger.log("Inferring polymorphic relations ...")
    return mapEntriesAsync(columns, (entityId, tableCols) => {
      const ref = entityRefFromId(entityId)
      const colNames = tableCols.map((c) => c.column_name)
      const polyCols = tableCols.filter((c) =>
        isPolymorphic(c.column_name, colNames)
      )
      return mapValuesAsync(
        Object.fromEntries(polyCols.map((c) => [c.column_name, c.column_name])),
        (c) =>
          getDistinctValues(
            ref,
            [c],
            opts
          )(conn).then((values) =>
            values.filter((v): v is string => typeof v === "string")
          )
      )
    })
  }

export const getDistinctValues =
  (ref: EntityRef, attribute: AttributePath, opts: ConnectorSchemaOpts) =>
  async (conn: Conn): Promise<AttributeValue[]> => {
    const sqlTable = buildSqlTable(ref)
    const sqlColumn = buildSqlColumn(attribute)
    const sampleSize = opts.sampleSize || connectorSchemaOptsDefaults.sampleSize
    return conn
      .query(
        `SELECT DISTINCT ${sqlColumn} AS value FROM ${sqlTable} WHERE ${sqlColumn} IS NOT NULL ORDER BY value FETCH FIRST ${sampleSize} ROWS ONLY`,
        [],
        "getDistinctValues"
      )
      .then((rows) =>
        rows.reduce<{ value: AttributeValue }[]>((acc, row) => {
          const [value] = row as any[]
          acc.push({ value })
          return acc
        }, [])
      )
      .catch((err) =>
        err instanceof Error &&
        err.message.match(/materialized view "[^"]+" has not been populated/)
          ? []
          : Promise.reject(err)
      )
      .catch(
        handleError(
          `Failed to get distinct values for '${attributeRefToId({ ...ref, attribute })}'`,
          [],
          opts
        )
      )
  }
