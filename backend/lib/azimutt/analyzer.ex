defmodule Azimutt.Analyzer do
  @moduledoc """
  A module to analyze a database.
  It's exposed on the web and used as a proxy to allow the browser to connect to a database.
  """
  alias Azimutt.Analyzer.ColumnStats
  alias Azimutt.Analyzer.Mysql
  alias Azimutt.Analyzer.Postgres
  alias Azimutt.Analyzer.QueryResults
  alias Azimutt.Analyzer.Schema
  alias Azimutt.Analyzer.TableStats
  alias Azimutt.Utils.Result
  alias Azimutt.Utils.Stringx

  @doc """
  Extract the schema of a database given its connection url.
  Optionally you can specify a schema name to extract only this one.
  ## Examples
      iex> Analyzer.get_schema("postgres://user:pass@localhost:5432/my_db", nil)
      {:ok, %Schema{}}
      iex> Analyzer.get_schema("bad", nil)
      {:error, "Database url not recognized"}
  """
  @spec get_schema(String.t(), String.t() | nil) :: Result.s(Schema.t())
  def get_schema(url, schema) do
    Postgres.get_schema(url, schema)
    |> Result.flat_map_error(fn _ -> Mysql.get_schema(url, schema) end)
    |> Result.or_else({:error, "Database url not recognized"})
    |> Result.map_error(&format_error/1)
  end

  @doc """
  Compute statistics for a table or column, given a database connection url.
  ## Examples
      iex> Analyzer.get_stats("postgres://user:pass@localhost:5432/my_db", "public", "users", "id")
      {:ok, %ColumnStats{}}
  """
  @spec get_stats(String.t(), String.t() | nil, String.t(), String.t() | nil) :: Result.s(TableStats.t() | ColumnStats.t())
  def get_stats(url, schema, table, column) do
    Postgres.get_stats(url, schema, table, column)
    |> Result.flat_map_error(fn _ -> Mysql.get_stats(url, schema, table, column) end)
    |> Result.or_else({:error, "Database url not recognized"})
    |> Result.map_error(&format_error/1)
  end

  @doc """
  Fetch rows from a database.
  ## Examples
      iex> Analyzer.get_rows("postgres://user:pass@localhost:5432/my_db", "public", "users", "name", "loic", 1)
      {:ok, %QueryResults{}}
  """
  @spec get_rows(String.t(), String.t() | nil, String.t(), String.t() | nil, String.t() | nil, pos_integer()) :: Result.s(QueryResults.t())
  def get_rows(url, schema, table, column, value, limit) do
    Postgres.get_rows(url, schema, table, column, value, limit)
    |> Result.flat_map_error(fn _ -> Mysql.get_rows(url, schema, table, column, value, limit) end)
    |> Result.or_else({:error, "Database url not recognized"})
    |> Result.map_error(&format_error/1)
  end

  @doc """
  Run a specific query on the required database.
  ## Examples
      iex> Analyzer.run_query("postgres://user:pass@localhost:5432/my_db", "SELECT * FROM users")
      {:ok, %QueryResults{}}
  """
  @spec run_query(String.t(), String.t()) :: Result.s(QueryResults.t())
  def run_query(url, query) do
    if String.starts_with?(query, "SELECT") && !String.contains?(query, ";") do
      Postgres.run_query(url, query)
      |> Result.flat_map_error(fn _ -> Mysql.run_query(url, query) end)
      |> Result.or_else({:error, "Database url not recognized"})
      |> Result.map_error(&format_error/1)
    else
      {:error, "Query must be a single SELECT."}
    end
  end

  defp format_error(err) do
    cond do
      err == :killed -> "Can't connect to the database"
      is_atom(err) || is_binary(err) -> err
      err -> Stringx.inspect(err)
    end
  end
end
