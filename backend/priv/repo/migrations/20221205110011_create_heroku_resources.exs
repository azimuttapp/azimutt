defmodule Azimutt.Repo.Migrations.CreateHerokuResources do
  use Ecto.Migration

  def change do
    create table(:heroku_resources, comments: "Heroku addon resources") do
      add :heroku_id, :uuid, null: false
      add :name, :string, null: false
      add :plan, :string, null: false
      add :region, :string, null: false
      add :options, :map
      add :callback, :string, null: false
      add :oauth_code, :uuid, null: false
      add :oauth_type, :string, null: false
      add :oauth_expire, :utc_datetime_usec, null: false
      add :deleted_at, :utc_datetime_usec

      timestamps()
    end

    create unique_index(:heroku_resources, [:heroku_id])
  end
end
