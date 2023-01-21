defmodule AzimuttWeb.Api.AnalyzerView do
  use AzimuttWeb, :view
  alias Azimutt.Analyzer.ColumnStats
  alias Azimutt.Analyzer.QueryResults
  alias Azimutt.Analyzer.Schema
  alias Azimutt.Analyzer.TableStats

  def render("schema.json", %{schema: %Schema{} = schema}), do: schema
  def render("stats.json", %{stats: %TableStats{} = stats}), do: stats
  def render("stats.json", %{stats: %ColumnStats{} = stats}), do: stats
  def render("query.json", %{results: %QueryResults{} = results}), do: results
end
