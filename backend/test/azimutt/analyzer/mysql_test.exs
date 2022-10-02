defmodule Azimutt.Analyzer.MysqlTest do
  use Azimutt.DataCase
  alias Azimutt.Analyzer.Mysql

  describe "mysql" do
    @tag :skip
    test "parse_url" do
      assert {:ok,
              %Mysql.DbConf{
                username: "user",
                password: "pass",
                hostname: "server.com",
                port: 3306,
                database: "database"
              }} = Mysql.parse_url("mysql://user:pass@server.com:3306/database")

      assert {:ok,
              %Mysql.DbConf{
                username: "user",
                password: "pass",
                hostname: "server.com",
                port: 3306,
                database: "database"
              }} = Mysql.parse_url("mariadb://user:pass@server.com:3306/database")
    end

    @tag :skip
    test "extract_schema" do
      # jdbc:mysql://localhost:port/dbname
      # jdbc:mariadb://sql4.lan.phpnet.org/lkws_wordpress
      url = "mariadb://lkws:@Dr4gNuxit;@sql4.lan.phpnet.org:3306/lkws_wordpress"
      {:ok, conf} = Mysql.parse_url(url)
      # IO.inspect(conf, label: "conf")
      {:ok, _schema} = Mysql.extract_schema(conf, nil)
      # IO.inspect(schema, label: "schema")
    end
  end
end
