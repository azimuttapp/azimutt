defmodule Azimutt.Repo.Migrations.CreateHerokuResources do
  use Ecto.Migration

  def change do
    create table(:heroku_resources, comment: "Heroku addon resources") do
      add :name, :string, null: false
      add :app, :string
      add :plan, :string, null: false
      add :region, :string, null: false
      add :options, :map
      add :callback, :string, null: false
      add :oauth_code, :uuid, null: false
      add :oauth_type, :string, null: false
      add :oauth_expire, :utc_datetime_usec, null: false
      add :organization_id, references(:organizations)
      timestamps()
      add :deleted_at, :utc_datetime_usec
    end

    alter table(:users) do
      modify(:avatar, :string, null: false, from: :string)
    end

    alter table(:organizations) do
      modify(:logo, :string, null: false, from: :string)
    end

    drop unique_index(:organizations, [:name])
  end
end
