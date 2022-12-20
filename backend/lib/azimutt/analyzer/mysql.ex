defmodule Azimutt.Analyzer.Mysql do
  @moduledoc "Analyzer implementation for MySQL"
  use TypedStruct
  alias Azimutt.Analyzer.ColumnStats
  alias Azimutt.Analyzer.QueryResults
  alias Azimutt.Analyzer.Schema
  alias Azimutt.Analyzer.TableStats
  alias Azimutt.Utils.Resource
  alias Azimutt.Utils.Result

  @spec get_schema(String.t(), String.t() | nil) :: Result.s(Result.s(Schema.t()))
  def get_schema(url, schema), do: parse_url(url) |> Result.map(&extract_schema(&1, schema))

  @spec get_stats(String.t(), String.t() | nil, String.t(), String.t() | nil) :: Result.s(Result.s(TableStats.t() | ColumnStats.t()))
  def get_stats(url, schema, table, column), do: parse_url(url) |> Result.map(&compute_stats(&1, schema, table, column))

  @spec get_rows(String.t(), String.t() | nil, String.t(), String.t() | nil, String.t() | nil, pos_integer()) :: Result.s(QueryResults.t())
  def get_rows(url, schema, table, column, value, limit),
    do: parse_url(url) |> Result.map(&fetch_rows(&1, schema, table, column, value, limit))

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
  def parse_url(_url) do
    #    Utils.parse_url(url)
    #    |> Result.flat_map(fn conf ->
    #      if conf.protocol == "mysql" || conf.protocol == "mariadb" do
    #        Result.ok(%DbConf{
    #          username: conf.username,
    #          password: conf.password,
    #          hostname: conf.hostname,
    #          port: conf.port,
    #          database: conf.database
    #        })
    #      else
    #        Result.error("Not a valid MySQL url")
    #      end
    #    end)

    {:error, "MySQL not implemented!"}
  end

  @spec extract_schema(DbConf.t(), String.t() | nil) :: Result.s(Schema.t())
  def extract_schema(conf, schema) do
    Resource.use(fn -> connect(conf) end, &disconnect(&1), fn pid ->
      get_tables(pid, schema)
      {:ok, %Schema{tables: [], relations: [], types: []}}
    end)
  end

  @spec compute_stats(DbConf.t(), String.t() | nil, String.t(), String.t() | nil) :: Result.s(TableStats.t() | ColumnStats.t())
  def compute_stats(conf, schema, table, _column) do
    Resource.use(fn -> connect(conf) end, &disconnect(&1), fn _pid ->
      {:ok, %TableStats{schema: schema, table: table, rows: 0}}
    end)
  end

  @spec fetch_rows(DbConf.t(), String.t() | nil, String.t(), String.t() | nil, String.t() | nil, pos_integer()) ::
          Result.s(QueryResults.t())
  def fetch_rows(conf, schema, table, column, value, limit) do
    exec_query(conf, "SELECT * FROM #{schema}.#{table} WHERE #{column}=#{value} LIMIT #{limit}")
  end

  @spec exec_query(DbConf.t(), String.t()) :: Result.s(QueryResults.t())
  def exec_query(conf, _query) do
    Resource.use(fn -> connect(conf) end, &disconnect(&1), fn _pid ->
      {:ok, %QueryResults{columns: [], values: []}}
    end)
  end

  defp connect(%DbConf{} = conf) do
    Postgrex.start_link(
      hostname: conf.hostname,
      port: conf.port,
      database: conf.database,
      username: conf.username,
      password: conf.password,
      # no retry on failed connection
      backoff_type: :stop
    )
  end

  defp disconnect(pid), do: GenServer.stop(pid)

  defp get_tables(pid, _schema) do
    tables = Postgrex.query(pid, "SHOW TABLES", [])
    # IO.inspect(tables, label: "tables")
    tables
  end
end
