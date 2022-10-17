defmodule AzimuttWeb.Api.AnalyzerView do
  use AzimuttWeb, :view
  alias Azimutt.Analyzer.Schema

  def render("schema.json", %{schema: %Schema{} = schema}) do
    schema
  end
end
