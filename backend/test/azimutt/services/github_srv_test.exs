defmodule Azimutt.Services.GithubSrvTest do
  use Azimutt.DataCase
  alias Azimutt.Services.GithubSrv

  describe "GithubSrv" do
    @tag :skip
    test "get_stargazers" do
      {:ok, p} = GithubSrv.paginate(2)
      {:ok, stargazers} = GithubSrv.get_stargazers("azimuttapp", "azimutt", p)
      IO.puts("Got #{stargazers.values |> length} stargazers")
      with_email = stargazers.values |> Enum.filter(fn s -> s.email && s.email != "" end)
      IO.puts("#{with_email |> length} emails: #{with_email |> Enum.map_join(", ", fn s -> s.email end)}")

      {:ok, p2} = GithubSrv.next(p, stargazers)
      {:ok, stargazers2} = GithubSrv.get_stargazers("azimuttapp", "azimutt", p2)
      IO.puts("Got #{stargazers2.values |> length} stargazers on page 2")
      with_email2 = stargazers2.values |> Enum.filter(fn s -> s.email && s.email != "" end)
      IO.puts("#{with_email2 |> length} emails: #{with_email2 |> Enum.map_join(", ", fn s -> s.email end)}")
    end

    @tag :skip
    test "get all" do
      {:ok, stargazers} = GithubSrv.fetch_all(fn p -> GithubSrv.get_stargazers("azimuttapp", "azimutt", p) end)
      IO.puts("Got #{stargazers |> length} stargazers")
      with_email = stargazers |> Enum.filter(fn s -> s.email && s.email != "" end)
      IO.puts("#{with_email |> length} emails: #{with_email |> Enum.map_join(", ", fn s -> s.email end)}")
    end
  end
end
