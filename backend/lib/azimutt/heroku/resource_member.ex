defmodule Azimutt.Heroku.ResourceMember do
  @moduledoc false
  use Ecto.Schema
  use Azimutt.Schema
  import Ecto.Changeset
  alias Azimutt.Accounts.User
  alias Azimutt.Heroku.Resource
  alias Azimutt.Heroku.ResourceMember

  @primary_key false
  schema "heroku_resource_members" do
    belongs_to :user, User, primary_key: true
    belongs_to :heroku_resource, Resource, primary_key: true
    timestamps(updated_at: false)
  end

  @doc false
  def new_member_changeset(%Resource{} = resource, %User{} = current_user) do
    %ResourceMember{}
    |> cast(%{}, [])
    |> put_assoc(:user, current_user)
    |> put_change(:heroku_resource, resource)
  end
end
