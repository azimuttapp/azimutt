defmodule AzimuttWeb.Api.MetadataView do
  use AzimuttWeb, :view
  alias AzimuttWeb.Utils.CtxParams

  def render("index.json", %{metadata: metadata, ctx: %CtxParams{} = _ctx}) do
    metadata
  end

  def render("table.json", %{metadata: metadata, ctx: %CtxParams{} = ctx}) do
    if ctx.expand |> Enum.member?("columns") do
      metadata
    else
      metadata
      |> Map.delete("columns")
    end
  end

  def render("column.json", %{metadata: metadata, ctx: %CtxParams{} = _ctx}) do
    metadata
  end
end
