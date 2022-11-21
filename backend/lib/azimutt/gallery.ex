defmodule Azimutt.Gallery do
  @moduledoc "Gallery module"
  import Ecto.Query, warn: false
  alias Azimutt.Gallery.Sample
  alias Azimutt.Projects.Project
  alias Azimutt.Repo
  alias Azimutt.Utils.Result

  def list_samples do
    public = :none

    Sample
    |> join(:inner, [s], p in Project, on: s.project_id == p.id)
    |> where([s, p], p.public != ^public)
    |> preload(:project)
    |> Repo.all()
  end

  def get_sample(slug) do
    public = :none

    Sample
    |> join(:inner, [s], p in Project, on: s.project_id == p.id)
    |> where([s, p], s.slug == ^slug and p.public != ^public)
    |> preload(:project)
    |> Repo.one()
    |> Result.from_nillable()
  end

  # Get 3 other samples
  def related_samples(sample) do
    list_samples |> Enum.filter(fn s -> s.id != sample.id end) |> Enum.shuffle() |> Enum.take(3)
  end

  def create_sample(attrs \\ %{}) do
    %Sample{}
    |> Sample.changeset(attrs)
    |> Repo.insert()
  end

  def delete_sample(%Sample{} = sample) do
    Repo.delete(sample)
  end
end
