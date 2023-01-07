defmodule Azimutt.Repo.Migrations.AddDataForUsersAndOrgas do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :data, :map, comment: "unstructured props for user"
    end

    alter table(:organizations) do
      add :data, :map, comment: "unstructured props for orgas"
    end
  end
end
