defmodule AzimuttWeb.Api.MetadataView do
  use AzimuttWeb, :view

  def render("index.json", %{metadata: metadata}) do
    metadata
  end

  def render("table.json", %{metadata: metadata, show_columns: show_columns}) do
    if show_columns do
      metadata
    else
      metadata |> Map.delete("columns")
    end
  end

  def render("column.json", %{metadata: metadata}) do
    metadata
  end
end
