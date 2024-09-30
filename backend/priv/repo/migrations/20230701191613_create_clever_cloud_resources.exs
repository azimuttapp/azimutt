defmodule Azimutt.Repo.Migrations.CreateCleverCloudResources do
  use Ecto.Migration

  def change do
    create table(:clever_cloud_resources, comment: "Clever Cloud addon resources") do
      add :addon_id, :string, null: false
      add :owner_id, :string, null: false
      add :owner_name, :string, null: false
      add :user_id, :string, null: false
      add :plan, :string, null: false
      add :region, :string, null: false
      add :callback_url, :string, null: false
      add :logplex_token, :string, null: false
      add :options, :map
      add :organization_id, references(:organizations)
      timestamps()
      add :deleted_at, :utc_datetime_usec
    end
  end
end
