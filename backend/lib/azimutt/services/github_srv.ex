defmodule Azimutt.Services.GithubSrv do
  @moduledoc false
  use TypedStruct
  alias Azimutt.Utils.Mapx
  alias Azimutt.Utils.Result

  # generate token here: https://github.com/settings/tokens
  # needs `user:email` and `read:user` scopes
  @token System.get_env("GITHUB_ACCESS_TOKEN")
  @max_size 100

  typedstruct module: Pagination, enforce: true do
    @moduledoc false
    field :size, pos_integer()
    field :cursor, String.t() | nil
  end

  typedstruct module: Page, enforce: true do
    @moduledoc false
    field :values, list(any())
    field :total_count, pos_integer()
    field :has_next, boolean()
    field :next_cursor, String.t() | nil
  end

  def get_stargazers(user, repo, %Pagination{} = p) do
    """
      query {
        repository(owner:"#{user}", name:"#{repo}") {
          stargazers(#{page_limit(p)}) {
            #{page_query()}
            edges {
              node { login, name, email, avatarUrl, location, bio, company, twitterUsername, url }
            }
          }
        }
      }
    """
    |> call()
    |> Result.map(fn data -> build_page(data["repository"]["stargazers"]) end)
  end

  def paginate(size) do
    if 0 < size && size <= @max_size do
      {:ok, %Pagination{size: size, cursor: nil}}
    else
      {:error, :invalid_page_size}
    end
  end

  def next(%Pagination{} = p, %Page{} = page) do
    if page.has_next && page.next_cursor do
      {:ok, %Pagination{size: p.size, cursor: page.next_cursor}}
    else
      {:error, :no_next_page}
    end
  end

  # fetch: lambda that takes a `Pagination` as parameter (see tests for example)
  def fetch_all(fetch, p \\ %Pagination{size: @max_size, cursor: nil}), do: fetch_all_rec(fetch, [], p)

  defp fetch_all_rec(fetch, values, %Pagination{} = p) do
    fetch.(p)
    |> Result.flat_map(fn page ->
      if page.has_next do
        next(p, page) |> Result.flat_map(fn p2 -> fetch_all_rec(fetch, values ++ page.values, p2) end)
      else
        {:ok, values ++ page.values}
      end
    end)
  end

  defp call(query) do
    body = Jason.encode!(%{query: query})
    headers = [{"Authorization", "bearer #{@token}"}]

    HTTPoison.post("https://api.github.com/graphql", body, headers)
    |> Result.flat_map(fn res -> Jason.decode(res.body) end)
    |> Result.flat_map(fn res ->
      if res["errors"] do
        {:error, res["errors"] |> Enum.map(&Mapx.atomize/1)}
      else
        {:ok, res["data"]}
      end
    end)
  end

  defp page_limit(%Pagination{} = p), do: "first: #{p.size}#{if(p.cursor, do: ", after: \"#{p.cursor}\"", else: "")}"

  defp page_query,
    do: """
      totalCount
      pageInfo { endCursor, hasNextPage }
    """

  defp build_page(data) do
    %Page{
      values: data["edges"] |> Enum.map(fn e -> Mapx.atomize(e["node"]) end),
      total_count: data["totalCount"],
      has_next: data["pageInfo"]["hasNextPage"],
      next_cursor: data["pageInfo"]["endCursor"]
    }
  end
end
