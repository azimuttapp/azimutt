defmodule Azimutt.Repo.Migrations.CreateTracking do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :name, :string, null: false
      add :data, :map, comment: "event entity data"
      add :details, :map, comment: "when additional data are needed"
      add :created_by, references(:users), null: false
      timestamps(updated_at: false)
      add :organization_id, references(:organizations)
      add :project_id, :uuid, comment: "no FK to keep records when projects are deleted"
    end

    create index(:events, [:name])
    create index(:events, [:created_by])
    create index(:events, [:created_at])
    create index(:events, [:organization_id])
    create index(:events, [:project_id])
  end
end
