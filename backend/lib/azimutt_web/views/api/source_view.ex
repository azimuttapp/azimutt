defmodule AzimuttWeb.Api.SourceView do
  use AzimuttWeb, :view
  alias AzimuttWeb.Utils.CtxParams

  def render("index.json", %{sources: sources, ctx: %CtxParams{} = ctx}) do
    render_many(sources, __MODULE__, "meta.json", ctx: ctx)
  end

  def render("meta.json", %{source: source, ctx: %CtxParams{} = _ctx}) do
    source
    |> Map.delete("content")
    |> Map.delete("tables")
    |> Map.delete("relations")
    |> Map.delete("types")
  end

  def render("show.json", %{source: source, ctx: %CtxParams{} = _ctx}) do
    source
  end
end
