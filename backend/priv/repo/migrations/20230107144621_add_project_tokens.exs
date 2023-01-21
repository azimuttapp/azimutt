defmodule Azimutt.Repo.Migrations.AddProjectAccessTokens do
  use Ecto.Migration

  def change do
    create table(:project_tokens, comment: "grant access to projects") do
      add :project_id, references(:projects), null: false
      add :name, :string, null: false
      add :nb_access, :integer, null: false
      add :last_access, :utc_datetime_usec
      add :expire_at, :utc_datetime_usec
      add :revoked_at, :utc_datetime_usec
      add :revoked_by, references(:users)
      timestamps(updated_at: false)
      add :created_by, references(:users), null: false
    end
  end
end
