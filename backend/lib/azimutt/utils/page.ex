defmodule Azimutt.Utils.Page do
  @moduledoc "A paged list of data."
  use TypedStruct
  import Ecto.Query
  alias Azimutt.Repo
  alias Azimutt.Utils.Intx
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
    # search (q=aaa)
    # sort (order=a,-b)
    # filters (f-name=login&f-user=abc)
  end

  def from_conn(conn, opts \\ %{}) do
    query = conn.query_params
    prefix = compute_prefix(opts[:prefix])

    %Info{
      path: conn.request_path,
      query: query,
      prefix: opts[:prefix],
      size: Intx.parse(query["#{prefix}size"]) |> Result.or_else(opts[:size] || 20),
      page: Intx.parse(query["#{prefix}page"]) |> Result.or_else(1)
    }
  end

  def wrap(items) do
    size = items |> length()

    %Page{
      info: %Info{path: "", query: %{}, prefix: nil, size: max(size, 1), page: 1},
      items: items,
      total: size
    }
  end

  def get(query, %Info{} = info) do
    items =
      query
      |> offset(^(info.size * (info.page - 1)))
      |> limit(^info.size)
      |> Repo.all()

    total = query |> Repo.aggregate(:count)
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
    prefix = compute_prefix(p.info.prefix)

    query =
      if page == 1 do
        p.info.query |> Map.delete("#{prefix}page") |> URI.encode_query()
      else
        p.info.query |> Map.put("#{prefix}page", page) |> URI.encode_query()
      end

    p.info.path <> if(query == "", do: "", else: "?#{query}")
  end

  defp compute_prefix(prefix), do: if(prefix == nil, do: "", else: "#{prefix}-")
end
