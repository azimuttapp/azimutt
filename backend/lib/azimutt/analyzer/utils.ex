defmodule Azimutt.Analyzer.Utils do
  @moduledoc false
  use TypedStruct
  alias Azimutt.Utils.{Nil, Result}

  typedstruct module: DbConf, enforce: true do
    @moduledoc false
    field :protocol, String.t()
    field :hostname, String.t()
    field :port, pos_integer() | nil
    field :database, String.t()
    field :username, String.t() | nil
    field :password, String.t() | nil
  end

  @spec parse_url(String.t()) :: Result.s(DbConf.t())
  def parse_url(url) do
    regex = ~r/([^:]+):\/\/(?:([^:]+):(.+)@)?([^:\/]+)(?::(\d+))?(?:\/([^\/]+))?/
    res = Regex.run(regex, url |> String.replace_prefix("jdbc:", ""))

    if res == nil do
      Result.error("Invalid url, expecting: '<protocol>://<user>:<pass>@<host>:<port>/<db>'")
    else
      Result.ok(%DbConf{
        protocol: Enum.at(res, 1) |> nil_if_empty(),
        username: Enum.at(res, 2) |> nil_if_empty(),
        password: Enum.at(res, 3) |> nil_if_empty(),
        hostname: Enum.at(res, 4),
        port: Enum.at(res, 5) |> nil_if_empty() |> Nil.safe(&String.to_integer/1),
        database: Enum.at(res, 6) |> nil_if_empty()
      })
    end
  end

  defp nil_if_empty(""), do: nil
  defp nil_if_empty(str), do: str
end
