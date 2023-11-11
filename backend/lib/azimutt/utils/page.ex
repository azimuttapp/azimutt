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
    field :prefix, String.t()
    field :size, pos_integer()
    field :page, pos_integer()
    field :search, String.t() | nil
    field :search_fields, list(atom())
    field :filters, any()
    field :sort, list(String.t())
  end

  def from_conn(conn, opts \\ %{}) do
    query = conn.query_params
    prefix = if(opts[:prefix] == nil, do: "", else: "#{opts[:prefix]}-")

    %Info{
      path: conn.request_path,
      query: query,
      prefix: prefix,
      size: Intx.parse(query["#{prefix}size"]) |> Result.or_else(opts[:size] || 20),
      page: Intx.parse(query["#{prefix}page"]) |> Result.or_else(1),
      search: query["#{prefix}q"],
      search_fields: opts[:search_on] || [],
      filters:
        query
        |> Map.filter(fn {k, _v} -> k |> String.starts_with?("#{prefix}f-") end)
        |> Mapx.map_keys(fn k -> k |> String.replace_leading("#{prefix}f-", "") end),
      sort: (query["#{prefix}sort"] || opts[:sort] || "") |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.filter(fn s -> s != "" end)
    }
  end

  def wrap(items) do
    size = items |> length()

    %Page{
      info: %Info{path: "", query: %{}, prefix: "", size: max(size, 1), page: 1, search: nil, search_fields: [], filters: %{}, sort: []},
      items: items,
      total: size
    }
  end

  def get(query, %Info{} = info) do
    new_query =
      query
      |> add_search(info.search, info.search_fields)
      |> add_filters(info.filters)
      |> order_by(^(info.sort |> Enum.map(&build_sort/1)))

    items =
      new_query
      |> offset(^(info.size * (info.page - 1)))
      |> limit(^info.size)
      |> Repo.all()

    total = new_query |> Repo.aggregate(:count)
    %Page{info: info, items: items, total: total}
  end

  defp add_search(query, term, fields) do
    if term != nil && term |> String.length() > 0 && fields |> length() > 0 do
      clause = fields |> Enum.reduce(false, fn f, q -> dynamic([t], ^q or like(field(t, ^f), ^"%#{term}%")) end)
      query |> where(^clause)
    else
      query
    end
  end

  defp add_filters(query, filters) do
    filters |> Enum.reduce(query, fn {key, value}, q -> q |> where(^filter_clause(String.to_atom(key), value)) end)
  end

  defp filter_clause(field, value) do
    cond do
      value |> String.contains?(",") ->
        value |> String.split(",") |> Enum.reduce(false, fn v, q -> dynamic([t], ^q or ^filter_clause(field, v)) end)

      value |> String.starts_with?("!") ->
        dynamic([t], not (^filter_clause(field, value |> String.trim_leading("!"))))

      value |> Timex.parse("{YYYY}-{0M}-{0D}") |> Result.is_ok?() ->
        dynamic([t], fragment("to_char(?, 'yyyy-mm-dd')", field(t, ^field)) == ^value)

      value |> Timex.parse("{YYYY}-{0M}") |> Result.is_ok?() ->
        dynamic([t], fragment("to_char(?, 'yyyy-mm')", field(t, ^field)) == ^value)

      value |> String.contains?("%") ->
        dynamic([t], like(field(t, ^field), ^value))

      value == "null" ->
        dynamic([t], is_nil(field(t, ^field)))

      true ->
        dynamic([t], field(t, ^field) == ^value)
    end
  end

  defp build_sort(sort) do
    if sort |> String.starts_with?("-") do
      {:desc, sort |> String.replace_leading("-", "") |> String.to_atom()}
    else
      {:asc, sort |> String.to_atom()}
    end
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
    key = "#{p.info.prefix}page"

    if page == 1 do
      p |> build_url(p.info.query |> Map.delete(key))
    else
      p |> build_url(p.info.query |> Map.put(key, page))
    end
  end

  def filter(%Page{} = p, name, value),
    do: p |> build_url(p.info.query |> Map.delete("#{p.info.prefix}page") |> Mapx.toggle("#{p.info.prefix}f-#{name}", value))

  def filtered?(%Page{} = p, name, value), do: p.info.query["#{p.info.prefix}f-#{name}"] == value

  def sort_up(%Page{} = p, name), do: p |> build_url(p.info.query |> Map.put("#{p.info.prefix}sort", name))
  def sort_down(%Page{} = p, name), do: p |> build_url(p.info.query |> Map.put("#{p.info.prefix}sort", "-#{name}"))
  def sorted_up?(%Page{} = p, name), do: p.info.sort |> Enum.any?(fn s -> s == name end)
  def sorted_down?(%Page{} = p, name), do: p.info.sort |> Enum.any?(fn s -> s == "-#{name}" end)

  defp build_url(%Page{} = p, query) do
    query_params = query |> URI.encode_query()
    p.info.path <> if(query_params == "", do: "", else: "?#{query_params}")
  end
end
