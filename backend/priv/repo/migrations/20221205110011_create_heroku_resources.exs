defmodule Azimutt.Repo.Migrations.CreateHerokuResources do
  use Ecto.Migration

  def change do
    create table(:heroku_resources, comments: "Heroku addon resources") do
      add :name, :string, null: false
      add :plan, :string, null: false
      add :region, :string, null: false
      add :options, :map
      add :callback, :string, null: false
      add :oauth_code, :uuid, null: false
      add :oauth_type, :string, null: false
      add :oauth_expire, :utc_datetime_usec, null: false
      add :project_id, :uuid, comment: "no FK to keep records when projects are deleted"
      timestamps()
      add :deleted_at, :utc_datetime_usec
    end

    create table(:heroku_resource_members, primary_key: false) do
      add :user_id, references(:users), primary_key: true, null: false
      add :heroku_resource_id, references(:heroku_resources), primary_key: true, null: false
      timestamps(updated_at: false)
    end
  end
end
