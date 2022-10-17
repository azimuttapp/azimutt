defmodule Azimutt.Analyzer.Postgrestest do
  use Azimutt.DataCase
  alias Azimutt.Analyzer.Postgres

  describe "postgres" do
    test "parse_url" do
      assert {:ok,
              %Postgres.DbConf{
                username: "user",
                password: "pass",
                hostname: "server.com",
                port: 5432,
                database: "database"
              }} = Postgres.parse_url("postgres://user:pass@server.com:5432/database")

      assert {:ok,
              %Postgres.DbConf{
                username: "user",
                password: "pass",
                hostname: "server.com",
                port: 5432,
                database: "database"
              }} = Postgres.parse_url("postgresql://user:pass@server.com:5432/database")
    end

    @tag :skip
    test "extract_schema" do
      url = "postgres://postgres:postgres@localhost:5432/azimutt_dev"
      {:ok, conf} = Postgres.parse_url(url)
      {:ok, _schema} = Postgres.extract_schema(conf, nil)
      # IO.inspect(schema, label: "schema")
    end
  end
end
