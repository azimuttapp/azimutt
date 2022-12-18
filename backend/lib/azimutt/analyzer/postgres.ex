defmodule Azimutt.Analyzer.Postgres do
  @moduledoc "Analyzer implementation for PostgreSQL"
  use TypedStruct
  alias Azimutt.Analyzer.ColumnStats
  alias Azimutt.Analyzer.QueryResults
  alias Azimutt.Analyzer.Schema
  alias Azimutt.Analyzer.TableStats
  alias Azimutt.Analyzer.Utils
  alias Azimutt.Utils.Mapx
  alias Azimutt.Utils.Nil
  alias Azimutt.Utils.Resource
  alias Azimutt.Utils.Result
  alias Azimutt.Utils.Stringx

  @spec get_schema(String.t(), String.t() | nil) :: Result.s(Result.s(Schema.t()))
  def get_schema(url, schema), do: parse_url(url) |> Result.map(&extract_schema(&1, schema))

  @spec get_stats(String.t(), String.t() | nil, String.t(), String.t() | nil) :: Result.s(Result.s(TableStats.t() | ColumnStats.t()))
  def get_stats(url, schema, table, column), do: parse_url(url) |> Result.map(&compute_stats(&1, schema, table, column))

  @spec run_query(String.t(), String.t()) :: Result.s(Result.s(QueryResults.t()))
  def run_query(url, query), do: parse_url(url) |> Result.map(&exec_query(&1, query))

  typedstruct module: DbConf, enforce: true do
    @moduledoc false
    field :hostname, String.t()
    field :port, pos_integer() | nil
    field :database, String.t()
    field :username, String.t() | nil
    field :password, String.t() | nil
  end

  @spec parse_url(String.t()) :: Result.s(DbConf.t())
  def parse_url(url) do
    Utils.parse_url(url)
    |> Result.flat_map(fn conf ->
      if conf.protocol == "postgres" || conf.protocol == "postgresql" do
        Result.ok(%DbConf{
          username: conf.username,
          password: conf.password,
          hostname: conf.hostname,
          port: conf.port,
          database: conf.database
        })
      else
        Result.error("Not a valid Postgres url")
      end
    end)
  end

  @spec extract_schema(DbConf.t(), String.t() | nil) :: Result.s(Schema.t())
  def extract_schema(%DbConf{} = conf, schema) do
    # ex: http://localhost:4000/api/v1/analyzer/schema?url=postgres://postgres:postgres@localhost:5432/azimutt_dev
    Resource.use(fn -> connect(conf) end, &disconnect(&1), fn pid ->
      with {:ok, columns} <- get_columns(pid, schema),
           {:ok, constraints} <- get_constraints(pid, schema),
           {:ok, indexes} <- get_indexes(pid, schema),
           {:ok, comments} <- get_comments(pid, schema),
           {:ok, relations} <- get_relations(pid, schema),
           {:ok, types} <- get_types(pid, schema),
           do: {:ok, build_schema(columns, constraints, indexes, comments, relations, types)}
    end)
  end

  @spec compute_stats(DbConf.t(), String.t() | nil, String.t(), String.t() | nil) :: Result.s(TableStats.t() | ColumnStats.t())
  def compute_stats(conf, schema, table, column) do
    Resource.use(fn -> connect(conf) end, &disconnect(&1), fn pid ->
      sql_table = "#{if(schema, do: "#{schema}.", else: "")}#{table}"

      if column do
        with {:ok, type} <- get_column_type(pid, schema, table, column),
             {:ok, stats} <- column_basics(pid, sql_table, column),
             {:ok, common_values} <- common_values(pid, sql_table, column),
             do:
               {:ok,
                %ColumnStats{
                  schema: schema,
                  table: table,
                  column: column,
                  type: type.name,
                  rows: stats.rows,
                  nulls: stats.nulls,
                  cardinality: stats.cardinality,
                  common_values: common_values
                }}
      else
        with {:ok, rows} <- count_rows(pid, sql_table),
             do: {:ok, %TableStats{schema: schema, table: table, rows: rows}}
      end
    end)
  end

  @spec connect(DbConf.t()) :: Result.s(pid())
  defp connect(%DbConf{} = conf) do
    # https://hexdocs.pm/postgrex/Postgrex.html#start_link/1
    # https://hexdocs.pm/db_connection/DBConnection.html#start_link/2
    Postgrex.start_link(
      hostname: conf.hostname,
      port: conf.port,
      database: conf.database,
      username: conf.username,
      password: conf.password,
      ssl: true,
      # no retry on failed connection
      backoff_type: :stop
    )
  end

  defp disconnect(pid), do: GenServer.stop(pid)

  typedstruct module: RawColumn, enforce: true do
    @moduledoc false
    field :table_schema, String.t()
    field :table_name, String.t()
    # table_kind: "r" (table), "v" (view), "m" (materialized view)
    field :table_kind, String.t()
    field :column_name, String.t()
    field :column_type, String.t()
    field :column_index, pos_integer()
    field :column_default, String.t() | nil
    field :column_nullable, boolean()
  end

  @spec get_columns(pid(), String.t() | nil) :: Result.s(list(RawColumn.t()))
  defp get_columns(pid, schema) do
    # https://www.postgresql.org/docs/current/catalog-pg-attribute.html: stores information about table columns. There will be exactly one row for every column in every table in the database.
    # https://www.postgresql.org/docs/current/catalog-pg-class.html: catalogs tables and most everything else that has columns or is otherwise similar to a table. This includes indexes (but see also pg_index), sequences (but see also pg_sequence), views, materialized views, composite types, and TOAST tables; see relkind.
    # https://www.postgresql.org/docs/current/catalog-pg-namespace.html: stores namespaces. A namespace is the structure underlying SQL schemas: each namespace can have a separate collection of relations, types, etc. without name conflicts.
    # https://www.postgresql.org/docs/current/catalog-pg-attrdef.html: stores column default values.
    Postgrex.query(
      pid,
      """
      SELECT n.nspname                            AS table_schema
           , c.relname                            AS table_name
           , c.relkind                            AS table_kind
           , a.attname                            AS column_name
           , format_type(a.atttypid, a.atttypmod) AS column_type
           , a.attnum                             AS column_index
           , pg_get_expr(d.adbin, d.adrelid)      AS column_default
           , NOT a.attnotnull                     AS column_nullable
      FROM pg_attribute a
        JOIN pg_class c ON c.oid = a.attrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        LEFT OUTER JOIN pg_attrdef d ON d.adrelid = c.oid AND d.adnum = a.attnum
      WHERE c.relkind IN ('r', 'v', 'm') AND a.attnum > 0 AND n.nspname #{in_schema(schema)}
      ORDER BY table_schema, table_name, column_index
      """,
      if(schema == nil, do: [], else: [schema])
    )
    |> Result.map_both(&format_error/1, &format_result(&1, RawColumn))
  end

  typedstruct module: RawConstraint, enforce: true do
    @moduledoc false
    # constraint_type: "p" (primary key), "c" (check)
    field :constraint_type, String.t()
    field :constraint_name, String.t()
    field :table_schema, String.t()
    field :table_name, String.t()
    field :columns, list(pos_integer())
    field :definition, String.t()
  end

  @spec get_constraints(pid(), String.t() | nil) :: Result.s(list(RawConstraint.t()))
  defp get_constraints(pid, schema) do
    # https://www.postgresql.org/docs/current/catalog-pg-constraint.html: stores check, primary key, unique, foreign key, and exclusion constraints on tables. Not-null constraints are represented in the pg_attribute catalog, not here.
    # https://www.postgresql.org/docs/current/catalog-pg-class.html: catalogs tables and most everything else that has columns or is otherwise similar to a table. This includes indexes (but see also pg_index), sequences (but see also pg_sequence), views, materialized views, composite types, and TOAST tables; see relkind.
    # https://www.postgresql.org/docs/current/catalog-pg-namespace.html: stores namespaces. A namespace is the structure underlying SQL schemas: each namespace can have a separate collection of relations, types, etc. without name conflicts.
    Postgrex.query(
      pid,
      """
      SELECT cn.contype                         AS constraint_type
           , cn.conname                         AS constraint_name
           , n.nspname                          AS table_schema
           , c.relname                          AS table_name
           , cn.conkey                          AS columns
           , pg_get_constraintdef(cn.oid, true) AS definition
      FROM pg_constraint cn
        JOIN pg_class c ON c.oid = cn.conrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE cn.contype IN ('p', 'c') AND n.nspname #{in_schema(schema)}
      ORDER BY table_schema, table_name, constraint_name
      """,
      if(schema == nil, do: [], else: [schema])
    )
    |> Result.map_both(&format_error/1, &format_result(&1, RawConstraint))
  end

  typedstruct module: RawIndex, enforce: true do
    @moduledoc false
    field :index_name, String.t()
    field :table_schema, String.t()
    field :table_name, String.t()
    field :columns, list(pos_integer())
    field :definition, String.t()
    field :is_unique, boolean()
  end

  @spec get_indexes(pid(), String.t() | nil) :: Result.s(list(RawIndex.t()))
  defp get_indexes(pid, schema) do
    # https://www.postgresql.org/docs/current/catalog-pg-index.html: contains part of the information about indexes. The rest is mostly in pg_class.
    # https://www.postgresql.org/docs/current/catalog-pg-class.html: catalogs tables and most everything else that has columns or is otherwise similar to a table. This includes indexes (but see also pg_index), sequences (but see also pg_sequence), views, materialized views, composite types, and TOAST tables; see relkind.
    # https://www.postgresql.org/docs/current/catalog-pg-namespace.html: stores namespaces. A namespace is the structure underlying SQL schemas: each namespace can have a separate collection of relations, types, etc. without name conflicts.
    Postgrex.query(
      pid,
      """
      SELECT ic.relname                             AS index_name
           , tn.nspname                             AS table_schema
           , tc.relname                             AS table_name
           , i.indkey::integer[]                    AS columns
           , pg_get_indexdef(i.indexrelid, 0, true) AS definition
           , i.indisunique                          AS is_unique
      FROM pg_index i
        JOIN pg_class ic ON ic.oid = i.indexrelid
        JOIN pg_class tc ON tc.oid = i.indrelid
        JOIN pg_namespace tn ON tn.oid = tc.relnamespace
      WHERE i.indisprimary = false AND tn.nspname #{in_schema(schema)}
      ORDER BY table_schema, table_name, index_name
      """,
      if(schema == nil, do: [], else: [schema])
    )
    |> Result.map_both(&format_error/1, &format_result(&1, RawIndex))
    |> Result.map(fn indexes -> indexes |> Enum.map(&format_index/1) end)
  end

  @spec format_index(RawIndex.t()) :: RawIndex.t()
  defp format_index(index) do
    case index.definition |> String.split(" USING ") do
      [_create, definition] -> %{index | definition: definition |> String.trim()}
      _ -> index
    end
  end

  typedstruct module: RawComment, enforce: true do
    @moduledoc false
    field :table_schema, String.t()
    field :table_name, String.t()
    field :column_name, String.t() | nil
    field :comment, String.t()
  end

  @spec get_comments(pid(), String.t() | nil) :: Result.s(list(RawComment.t()))
  defp get_comments(pid, schema) do
    # https://www.postgresql.org/docs/current/catalog-pg-description.html: stores optional descriptions (comments) for each database object.
    # https://www.postgresql.org/docs/current/catalog-pg-class.html: catalogs tables and most everything else that has columns or is otherwise similar to a table. This includes indexes (but see also pg_index), sequences (but see also pg_sequence), views, materialized views, composite types, and TOAST tables; see relkind.
    # https://www.postgresql.org/docs/current/catalog-pg-namespace.html: stores namespaces. A namespace is the structure underlying SQL schemas: each namespace can have a separate collection of relations, types, etc. without name conflicts.
    # https://www.postgresql.org/docs/current/catalog-pg-attribute.html: stores information about table columns. There will be exactly one row for every column in every table in the database.
    Postgrex.query(
      pid,
      """
      SELECT n.nspname     AS table_schema
           , c.relname     AS table_name
           , a.attname     AS column_name
           , d.description AS comment
      FROM pg_description d
        JOIN pg_class c ON c.oid = d.objoid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        LEFT OUTER JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = d.objsubid
      WHERE c.relkind IN ('r', 'v', 'm') AND n.nspname #{in_schema(schema)}
      ORDER BY table_schema, table_name, column_name
      """,
      if(schema == nil, do: [], else: [schema])
    )
    |> Result.map_both(&format_error/1, &format_result(&1, RawComment))
  end

  typedstruct module: RawRelation, enforce: true do
    @moduledoc false
    field :constraint_name, String.t()
    field :table_schema, String.t()
    field :table_name, String.t()
    field :columns, list(pos_integer())
    field :target_schema, String.t()
    field :target_table, String.t()
    field :target_columns, list(pos_integer())
  end

  @spec get_relations(pid(), String.t() | nil) :: Result.s(list(RawRelation.t()))
  defp get_relations(pid, schema) do
    # https://www.postgresql.org/docs/current/catalog-pg-constraint.html: stores check, primary key, unique, foreign key, and exclusion constraints on tables. Not-null constraints are represented in the pg_attribute catalog, not here.
    # https://www.postgresql.org/docs/current/catalog-pg-class.html: catalogs tables and most everything else that has columns or is otherwise similar to a table. This includes indexes (but see also pg_index), sequences (but see also pg_sequence), views, materialized views, composite types, and TOAST tables; see relkind.
    # https://www.postgresql.org/docs/current/catalog-pg-namespace.html: stores namespaces. A namespace is the structure underlying SQL schemas: each namespace can have a separate collection of relations, types, etc. without name conflicts.
    Postgrex.query(
      pid,
      """
      SELECT cn.conname AS constraint_name
           , n.nspname  AS table_schema
           , c.relname  AS table_name
           , cn.conkey  AS columns
           , tn.nspname AS target_schema
           , tc.relname AS target_table
           , cn.confkey AS target_columns
      FROM pg_constraint cn
        JOIN pg_class c ON c.oid = cn.conrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        JOIN pg_class tc ON tc.oid = cn.confrelid
        JOIN pg_namespace tn ON tn.oid = tc.relnamespace
      WHERE cn.contype IN ('f') AND n.nspname #{in_schema(schema)}
      ORDER BY table_schema, table_name, constraint_name
      """,
      if(schema == nil, do: [], else: [schema])
    )
    |> Result.map_both(&format_error/1, &format_result(&1, RawRelation))
  end

  typedstruct module: RawType, enforce: true do
    @moduledoc false
    field :type_schema, String.t()
    field :type_name, String.t()
    field :internal_name, String.t()

    # type_kind: "b": base, "c": composite, "d": domain, "e": enum, "p": pseudo-type, "r": range, "m": multirange
    field :type_kind, String.t()
    field :enum_values, list(String.t())
    field :type_comment, String.t() | nil
  end

  @spec get_types(pid(), String.t() | nil) :: Result.s(list(RawType.t()))
  defp get_types(pid, schema) do
    # https://www.postgresql.org/docs/current/catalog-pg-enum.html: values and labels for each enum type
    # https://www.postgresql.org/docs/current/catalog-pg-type.html: stores data types
    # https://www.postgresql.org/docs/current/catalog-pg-class.html: catalogs tables and most everything else that has columns or is otherwise similar to a table. This includes indexes (but see also pg_index), sequences (but see also pg_sequence), views, materialized views, composite types, and TOAST tables; see relkind.
    # https://www.postgresql.org/docs/current/catalog-pg-namespace.html: stores namespaces. A namespace is the structure underlying SQL schemas: each namespace can have a separate collection of relations, types, etc. without name conflicts.
    Postgrex.query(
      pid,
      """
      SELECT n.nspname                                AS type_schema
           , format_type(t.oid, NULL)                 AS type_name
           , t.typname                                AS internal_name
           , t.typtype                                AS type_kind
           , array(SELECT enumlabel
                   FROM pg_enum
                   WHERE enumtypid = t.oid
                   ORDER BY enumsortorder)::varchar[] AS enum_values
           , obj_description(t.oid, 'pg_type')        AS type_comment
      FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
      WHERE (t.typrelid = 0 OR (SELECT c.relkind = 'c' FROM pg_class c WHERE c.oid = t.typrelid))
        AND NOT EXISTS(SELECT 1 FROM pg_type WHERE oid = t.typelem AND typarray = t.oid)
        AND n.nspname #{in_schema(schema)}
      ORDER BY type_schema, type_name
      """,
      if(schema == nil, do: [], else: [schema])
    )
    |> Result.map_both(&format_error/1, &format_result(&1, RawType))
  end

  defp build_schema(columns, constraints, indexes, comments, relations, types) do
    columns_by_table = columns |> Enum.group_by(&to_table_id/1)
    constraints_by_table = constraints |> Enum.group_by(&to_table_id/1)
    indexes_by_table = indexes |> Enum.group_by(&to_table_id/1)
    comments_by_table = comments |> Enum.group_by(&to_table_id/1)

    columns_by_table_and_index =
      columns_by_table
      |> Mapx.map_values(fn cols ->
        cols |> Enum.group_by(& &1.column_index) |> Mapx.map_values(&List.first/1)
      end)

    column_index_to_name = fn table_id, column_index ->
      columns_by_table_and_index
      |> Map.get(table_id, %{})
      |> Map.get(column_index, %{})
      |> Map.get(:column_name, "unknown")
    end

    %Schema{
      tables:
        columns_by_table
        |> Enum.map(fn {table_id, table_columns} ->
          build_table(
            table_id,
            table_columns,
            constraints_by_table |> Map.get(table_id, []),
            indexes_by_table |> Map.get(table_id, []),
            comments_by_table |> Map.get(table_id, []),
            column_index_to_name
          )
        end),
      relations: relations |> Enum.map(&build_relation(&1, column_index_to_name)),
      types: types |> Enum.map(&build_type/1)
    }
  end

  defp build_table(table_id, columns, constraints, indexes, comments, column_index_to_name) do
    table = columns |> List.first()
    to_column_name = &column_index_to_name.(table_id, &1)

    %Schema.Table{
      schema: table.table_schema,
      table: table.table_name,
      view: table.table_kind != "r",
      columns:
        columns
        |> Enum.sort_by(& &1.column_index)
        |> Enum.map(&build_column(&1, comments)),
      primaryKey:
        constraints
        |> Enum.find(&(&1.constraint_type == "p"))
        |> Nil.safe(&build_primary_key(&1, to_column_name)),
      uniques:
        indexes
        |> Enum.filter(& &1.is_unique)
        |> Enum.map(&build_unique(&1, to_column_name)),
      indexes:
        indexes
        |> Enum.filter(&(!&1.is_unique))
        |> Enum.map(&build_index(&1, to_column_name)),
      checks:
        constraints
        |> Enum.filter(&(&1.constraint_type == "c"))
        |> Enum.map(&build_check(&1, to_column_name)),
      comment: comments |> Enum.find(&(&1.column_name == nil)) |> Nil.safe(& &1.comment)
    }
  end

  defp build_column(col, comments) do
    %Schema.Column{
      name: col.column_name,
      type: col.column_type,
      nullable: col.column_nullable,
      default: col.column_default,
      comment: comments |> Enum.find(&(&1.column_name == col.column_name)) |> Nil.safe(& &1.comment)
    }
  end

  defp build_primary_key(constraint, to_column_name) do
    %Schema.PrimaryKey{
      name: constraint.constraint_name,
      columns: constraint.columns |> Enum.map(to_column_name)
    }
  end

  defp build_unique(index, to_column_name) do
    %Schema.Unique{
      name: index.index_name,
      columns: index.columns |> Enum.map(to_column_name),
      definition: index.definition
    }
  end

  defp build_index(index, to_column_name) do
    %Schema.Index{
      name: index.index_name,
      columns: index.columns |> Enum.map(to_column_name),
      definition: index.definition
    }
  end

  defp build_check(constraint, to_column_name) do
    %Schema.Check{
      name: constraint.constraint_name,
      columns: constraint.columns |> Enum.map(to_column_name),
      predicate: constraint.definition |> String.replace(~r/^CHECK/i, "") |> String.trim()
    }
  end

  defp build_relation(relation, column_index_to_name) do
    src_table_id = to_table_id(relation)

    ref_table_id = to_table_id(%{table_schema: relation.target_schema, table_name: relation.target_table})

    %Schema.Relation{
      name: relation.constraint_name,
      src: %Schema.TableRef{schema: relation.table_schema, table: relation.table_name},
      ref: %Schema.TableRef{schema: relation.target_schema, table: relation.target_table},
      columns:
        List.zip([
          relation.columns |> Enum.map(&column_index_to_name.(src_table_id, &1)),
          relation.target_columns |> Enum.map(&column_index_to_name.(ref_table_id, &1))
        ])
        |> Enum.map(fn {src, ref} -> %Schema.ColumnLink{src: src, ref: ref} end)
    }
  end

  defp build_type(type) do
    %Schema.Type{
      schema: type.type_schema,
      name: type.type_name,
      values: if(type.type_kind == "e", do: type.enum_values, else: nil)
    }
  end

  defp to_table_id(item), do: "#{item.table_schema}.#{item.table_name}"

  @spec count_rows(pid(), String.t()) :: Result.s(integer())
  defp count_rows(pid, sql_table) do
    Postgrex.query(pid, "SELECT count(*) FROM #{sql_table}", [])
    |> Result.map_both(&format_error/1, fn res -> res.rows |> hd() |> hd() end)
  end

  typedstruct module: ColumnType, enforce: true do
    @moduledoc false
    field :formatted, String.t()
    field :name, String.t()
    field :category, String.t()
  end

  @spec get_column_type(pid(), String.t() | nil, String.t(), String.t()) :: Result.s(ColumnType.t())
  defp get_column_type(pid, schema, table, column) do
    Postgrex.query(
      pid,
      """
      SELECT format_type(a.atttypid, a.atttypmod) AS formatted
           , t.typname                            AS name
           , t.typcategory                        AS category
      FROM pg_attribute a
         JOIN pg_class c ON c.oid = a.attrelid
         JOIN pg_namespace n ON n.oid = c.relnamespace
         JOIN pg_type t ON t.oid = a.atttypid
      WHERE c.relname=$1 AND a.attname=$2#{if(schema, do: " AND n.nspname=$3", else: "")}
      """,
      if(schema, do: [table, column, schema], else: [table, column])
    )
    |> Result.map_both(&format_error/1, fn res ->
      row = res.rows |> hd()

      %ColumnType{
        formatted: row |> Enum.at(0),
        name: row |> Enum.at(1),
        category: row |> Enum.at(2)
      }
    end)
  end

  typedstruct module: ColumnCounts, enforce: true do
    @moduledoc false
    field :rows, pos_integer()
    field :cardinality, pos_integer()
    field :nulls, pos_integer()
  end

  @spec column_basics(pid(), String.t(), String.t()) :: Result.s(ColumnCounts.t())
  defp column_basics(pid, sql_table, column) do
    Postgrex.query(
      pid,
      """
      SELECT count(*)                                                    AS rows
           , count(distinct #{column})                                   AS cardinality
           , (SELECT count(*) FROM #{sql_table} WHERE #{column} IS NULL) AS nulls
      FROM #{sql_table}
      """,
      []
    )
    |> Result.map_both(&format_error/1, fn res ->
      row = res.rows |> hd()

      %ColumnCounts{
        rows: row |> Enum.at(0),
        cardinality: row |> Enum.at(1),
        nulls: row |> Enum.at(2)
      }
    end)
  end

  @spec common_values(pid(), String.t(), String.t()) :: Result.s(map())
  defp common_values(pid, table, column) do
    Postgrex.query(pid, "SELECT #{column}, count(*) FROM #{table} GROUP BY #{column} ORDER BY count(*) DESC LIMIT 10", [])
    |> Result.map_both(&format_error/1, fn res ->
      res.rows |> Enum.map(fn row -> {row |> Enum.at(0) |> format_value, row |> Enum.at(1)} end) |> Map.new()
    end)
  end

  @spec exec_query(DbConf.t(), String.t()) :: Result.s(QueryResults.t())
  def exec_query(conf, query) do
    Resource.use(fn -> connect(conf) end, &disconnect(&1), fn pid ->
      Postgrex.query(pid, query, [])
      |> Result.map_both(&format_error/1, fn res ->
        %QueryResults{
          query: query,
          columns: res.columns,
          values: res.rows |> Enum.map(fn row -> row |> Enum.map(&format_value/1) end)
        }
      end)
    end)
  end

  # HELPERS

  defp in_schema(schema),
    do: if(schema == nil, do: "NOT IN ('information_schema', 'pg_catalog')", else: "IN ($1)")

  defp format_result(%Postgrex.Result{} = res, struct) do
    columns = res.columns |> Enum.map(&String.to_atom/1)
    res.rows |> Enum.map(fn row -> struct(struct, List.zip([columns, row])) end)
  end

  # other interesting fields: `res.query` & `res.postgres.position`
  defp format_error(%Postgrex.Error{} = err),
    do:
      err.postgres.message <>
        if(err.postgres[:hint] == nil, do: "", else: ". " <> err.postgres[:hint])

  defp format_error(%Postgrex.QueryError{} = err), do: err.message
  defp format_error(%DBConnection.ConnectionError{} = err), do: err.message
  defp format_error(err), do: "Unknown error: #{Stringx.inspect(err)}"

  defp format_value(value) when is_binary(value) and byte_size(value) == 16, do: Ecto.UUID.cast!(value)
  # defp format_value(value) when is_nil(value), do: "null"
  defp format_value(value), do: value
end
