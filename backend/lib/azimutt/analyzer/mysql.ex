defmodule Azimutt.Analyzer.Mysql do
  @moduledoc "Analyzer implementation for MySQL"
  use TypedStruct
  alias Azimutt.Analyzer.Schema
  alias Azimutt.Utils.{Resource, Result}

  @spec get_schema(String.t(), String.t() | nil) :: Result.s(Result.s(Schema.t()))
  def get_schema(url, schema),
    do: parse_url(url) |> Result.map(&extract_schema(&1, schema))

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
