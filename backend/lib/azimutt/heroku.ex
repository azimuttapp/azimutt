defmodule Azimutt.Heroku do
  @moduledoc "Context for the Heroku addon"
  import Ecto.Query, warn: false
  alias Azimutt.Heroku.Resource
  alias Azimutt.Repo
  alias Azimutt.Utils.Result

  def get_resource(heroku_id), do: Repo.get_by(Resource, heroku_id: heroku_id) |> Result.from_nillable()

  def create_resource(attrs \\ %{}) do
    %Resource{}
    |> Resource.create_changeset(attrs)
    |> Repo.insert()
  end

  def update_resource(%Resource{} = resource, attrs, now) do
    resource
    |> Resource.update_changeset(attrs, now)
    |> Repo.update()
  end

  def delete_resource(%Resource{} = resource, now) do
    resource
    |> Resource.delete_changeset(now)
    |> Repo.update()
  end
end
