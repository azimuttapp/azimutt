defmodule Azimutt.Gallery.Sample do
  @moduledoc "The gallery sample schema"
  use Ecto.Schema
  use Azimutt.Schema
  import Ecto.Changeset
  alias Azimutt.Projects.Project

  schema "gallery" do
    belongs_to :project, Project
    field :slug, :string
    field :icon, :string
    field :color, :string
    field :website, :string
    field :banner, :string
    field :tips, :string
    field :description, :string
    field :analysis, :string
    timestamps()
  end

  @doc false
  def changeset(sample, attrs) do
    sample
    |> cast(attrs, [:slug, :icon, :color, :website, :banner, :tips, :description, :analysis])
    |> validate_required([:slug, :icon, :color, :website, :banner, :tips, :description, :analysis])
  end
end
