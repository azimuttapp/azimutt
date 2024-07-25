defmodule Azimutt.Repo.Migrations.AddUserRights do
  use Ecto.Migration

  def change do
    alter table(:organization_members) do
      add :role, :string, null: false, default: "owner", comment: "values: owner, writer, reader"
    end

    alter table(:organization_invitations) do
      add :role, :string, comment: "values: owner, writer, reader"
    end
  end
end
