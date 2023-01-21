defmodule Azimutt do
  @moduledoc """
  Azimutt keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  alias Azimutt.Utils.Stringx

  def config([main_key | rest] = keyspace) when is_list(keyspace) do
    main = Application.fetch_env!(:azimutt, main_key)

    Enum.reduce(rest, main, fn next_key, current ->
      case Keyword.fetch(current, next_key) do
        {:ok, val} -> val
        :error -> raise ArgumentError, "no config found under #{Stringx.inspect(keyspace)}"
      end
    end)
  end

  def config(key, default \\ nil) when is_atom(key) do
    Application.get_env(:azimutt, key, default)
  end
end
