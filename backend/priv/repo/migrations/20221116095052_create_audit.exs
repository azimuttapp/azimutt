defmodule Azimutt.Repo.Migrations.CreateAudit do
  use Ecto.Migration

  def change do
    create table(:audit) do
      add :name, :string, null: false
      add :details, :map, comment: "when more data needs to be saved"
      add :created_by, references(:users), null: false
      timestamps(updated_at: false)
      add :organization_id, references(:organizations)
      add :project_id, :uuid, comment: "no FK to keep records when projects are deleted"
    end

    create index(:audit, [:name])
    create index(:audit, [:created_by])
    create index(:audit, [:created_at])
    create index(:audit, [:organization_id])
    create index(:audit, [:project_id])
  end
end
