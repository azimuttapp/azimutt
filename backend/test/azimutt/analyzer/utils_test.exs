defmodule Azimutt.Analyzer.UtilsTest do
  use Azimutt.DataCase
  alias Azimutt.Analyzer.Utils

  describe "utils" do
    test "parse full url" do
      assert {:ok,
              %Utils.DbConf{
                protocol: "mysql",
                username: "dbuser",
                password: "dbpassword",
                hostname: "server.com",
                port: 5432,
                database: "mydb"
              }} = Utils.parse_url("mysql://dbuser:dbpassword@server.com:5432/mydb")
    end

    test "parse minimal url" do
      assert {:ok,
              %Utils.DbConf{
                protocol: "postgres",
                username: nil,
                password: nil,
                hostname: "db.co",
                port: nil,
                database: nil
              }} = Utils.parse_url("postgres://db.co")
    end

    test "parse jdbc url" do
      assert {:ok,
              %Utils.DbConf{
                protocol: "mariadb",
                username: nil,
                password: nil,
                hostname: "localhost",
                port: 3306,
                database: nil
              }} = Utils.parse_url("jdbc:mariadb://localhost:3306")
    end

    test "parse password with @" do
      assert {:ok,
              %Utils.DbConf{
                protocol: "mariadb",
                username: "user",
                password: "abc@def",
                hostname: "demo.fr",
                port: nil,
                database: "db"
              }} = Utils.parse_url("mariadb://user:abc@def@demo.fr/db")
    end
  end
end
