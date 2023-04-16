defmodule Azimutt.Repo.Migrations.RemoveProfileDataFromUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :company
      remove :location
      remove :description
    end

    alter table(:organizations) do
      remove :contact_email
      remove :location
    end
  end
end
