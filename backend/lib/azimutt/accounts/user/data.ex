defmodule Azimutt.Accounts.User.Data do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias Azimutt.Accounts.User

  @primary_key false
  embedded_schema do
    # see user_auth.ex#track_attribution cookie for format
    field :attributed_from, :string
    field :attributed_to, :string
    field :start_checklist, {:array, :string}, default: []
  end

  def changeset(%User.Data{} = data, attrs) do
    data
    |> cast(attrs, [:attributed_from, :attributed_to, :start_checklist])
  end
end
