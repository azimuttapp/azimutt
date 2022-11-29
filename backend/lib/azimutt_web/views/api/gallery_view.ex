defmodule AzimuttWeb.Api.GalleryView do
  use AzimuttWeb, :view
  alias Azimutt.Gallery.Sample
  alias AzimuttWeb.Utils.CtxParams

  def render("index.json", %{samples: samples}) do
    render_many(samples, __MODULE__, "show.json", ctx: CtxParams.empty())
  end

  def render("show.json", %{gallery: %Sample{} = sample, ctx: %CtxParams{} = ctx}) do
    %{
      slug: sample.slug,
      color: sample.color,
      icon: sample.icon,
      name: sample.project.name,
      description: sample.tips,
      project_id: sample.project.id,
      nb_tables: sample.project.nb_tables
    }
  end
end
