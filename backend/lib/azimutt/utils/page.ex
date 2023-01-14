defmodule Azimutt.Utils.Page do
  @moduledoc "A paged list of data."
  use TypedStruct
  import Ecto.Query
  alias Azimutt.Repo
  alias Azimutt.Utils.Intx
  alias Azimutt.Utils.Mapx
  alias Azimutt.Utils.Page
  alias Azimutt.Utils.Page.Info
  alias Azimutt.Utils.Result
  alias Azimutt.Utils.Stringx

  typedstruct enforce: true do
    @derive Jason.Encoder
    field :info, Info.t()
    field :items, list(any())
    field :total, pos_integer()
  end

  typedstruct module: Info, enforce: true do
    @moduledoc false
    @derive Jason.Encoder
    field :path, String.t()
    field :query, any()
    field :prefix, String.t() | nil
    field :size, pos_integer()
    field :page, pos_integer()
    field :filters, any()
    # search (q=aaa)
    # sort (order=a,-b)
  end

  def from_conn(conn, opts \\ %{}) do
    query = conn.query_params
    prefix = compute_prefix(opts[:prefix])

    %Info{
      path: conn.request_path,
      query: query,
      prefix: opts[:prefix],
      size: Intx.parse(query["#{prefix}size"]) |> Result.or_else(opts[:size] || 20),
      page: Intx.parse(query["#{prefix}page"]) |> Result.or_else(1),
      filters:
        query
        |> Map.filter(fn {k, _v} -> k |> String.starts_with?("#{prefix}f-") end)
        |> Mapx.map_keys(fn k -> k |> String.replace_leading("#{prefix}f-", "") end)
        |> Mapx.atomize()
    }
  end

  def wrap(items) do
    size = items |> length()

    %Page{
      info: %Info{path: "", query: %{}, prefix: nil, size: max(size, 1), page: 1, filters: %{}},
      items: items,
      total: size
    }
  end

  def get(query, %Info{} = info) do
    new_query = query |> where(^(info.filters |> Map.to_list()))

    items =
      new_query
      |> offset(^(info.size * (info.page - 1)))
      |> limit(^info.size)
      |> Repo.all()

    total = new_query |> Repo.aggregate(:count)
    %Page{info: info, items: items, total: total}
  end

  def first(%Page{} = p), do: p.info.size * (p.info.page - 1) + 1
  def last(%Page{} = p), do: Page.first(p) + (p.items |> length()) - 1
  def first_page(%Page{} = _p), do: 1
  def last_page(%Page{} = p), do: (p.total / p.info.size) |> ceil()
  def has_pagination(%Page{} = p), do: first_page(p) < last_page(p)
  def has_previous(%Page{} = p), do: first_page(p) < p.info.page
  def has_next(%Page{} = p), do: p.info.page < last_page(p)

  def title(%Page{} = p, name) do
    if has_pagination(p) do
      "#{name |> Stringx.plural() |> String.capitalize()} #{Page.first(p)} to #{Page.last(p)} of #{p.total}"
    else
      p.total |> Stringx.pluralize(name)
    end
  end

  def first_pages(%Page{} = p) do
    if(first_page(p) + 2 < p.info.page, do: [1], else: [])
  end

  def current_pages(%Page{} = p) do
    last = last_page(p)
    [p.info.page - 2, p.info.page - 1, p.info.page, p.info.page + 1, p.info.page + 2] |> Enum.filter(fn p -> 0 < p && p <= last end)
  end

  def last_pages(%Page{} = p) do
    last = last_page(p)
    if(p.info.page < last - 2, do: [last], else: [])
  end

  def change_page(%Page{} = p, page) do
    key = "#{compute_prefix(p.info.prefix)}page"

    if page == 1 do
      p |> build_url(p.info.query |> Map.delete(key))
    else
      p |> build_url(p.info.query |> Map.put(key, page))
    end
  end

  def filter(%Page{} = p, name, value) do
    prefix = compute_prefix(p.info.prefix)
    key = "#{prefix}f-#{name}"
    p |> build_url(p.info.query |> Map.delete("#{prefix}page") |> Mapx.toggle(key, value))
  end

  def filtered?(%Page{} = p, name, value) do
    prefix = compute_prefix(p.info.prefix)
    key = "#{prefix}f-#{name}"
    p.info.query[key] == value
  end

  defp compute_prefix(prefix), do: if(prefix == nil, do: "", else: "#{prefix}-")

  defp build_url(%Page{} = p, query) do
    query_params = query |> URI.encode_query()
    p.info.path <> if(query_params == "", do: "", else: "?#{query_params}")
  end
end
