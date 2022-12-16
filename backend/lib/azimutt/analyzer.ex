defmodule Azimutt.Analyzer do
  @moduledoc """
  A module to analyze a database.
  It's exposed on the web and used as a proxy to allow the browser to connect to a database.
  """
  alias Azimutt.Utils.Result
  alias Azimutt.Utils.Stringx
  alias Azimutt.Analyzer.{Mysql, Postgres, Schema}

  @doc """
  Extract the schema of a database given its connection url.
  Optionally you can specify a schema name to extract only this one.
  ## Examples
      iex> Analyzer.get_schema("postgres://postgres:postgres@localhost:5432/my_db", nil)
      {:ok, %Schema{}}
      iex> Analyzer.get_schema("bad", nil)
      {:error, "Database url not recognized"}
  """
  @spec get_schema(String.t(), String.t() | nil) :: Result.s(Schema.t())
  def get_schema(url, schema) do
    Postgres.get_schema(url, schema)
    |> Result.flat_map_error(fn _ -> Mysql.get_schema(url, schema) end)
    |> Result.or_else({:error, "Database url not recognized"})
    |> Result.map_error(fn
      :killed -> "Can't connect to the database"
      e -> if(is_binary(e), do: e, else: Stringx.inspect(e))
    end)
  end
end
