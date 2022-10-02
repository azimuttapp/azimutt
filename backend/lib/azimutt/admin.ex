defmodule Azimutt.Admin do
  @moduledoc """
  The Admin context.
  """

  import Ecto.Query, warn: false
  alias Azimutt.Organizations.Organization
  alias Azimutt.Repo

  def list_organizations do
    Organization
    |> preload(:members)
    |> preload(:projects)
    |> preload(:invitations)
    |> Repo.all()
  end
end
