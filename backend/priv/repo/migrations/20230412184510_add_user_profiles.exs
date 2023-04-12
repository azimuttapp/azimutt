defmodule Azimutt.Repo.Migrations.AddUserProfiles do
  use Ecto.Migration

  def change do
    create table(:user_profiles, comments: "store complementary data on users") do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :initial_usage, :string
      add :initial_usecase, :string
      add :role, :string
      add :location, :string
      add :description, :text
      add :company, :string
      add :company_size, :integer
      add :discovered_by, :string
      add :previously_tried, {:array, :string}
      add :product_updates, :boolean
      timestamps()
    end

    alter table(:users) do
      add :onboarding, :string, comment: "current onboarding step when not finished"
      add :provider_data, :map, comment: "connection object from provider"
    end
  end
end
