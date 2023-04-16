defmodule Azimutt.Repo.Migrations.CopyProfilesData do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"

    execute "INSERT INTO user_profiles (id, user_id, location, description, company, created_at, updated_at) " <>
              "SELECT uuid_generate_v4(), id, location, description, company, now(), now() FROM users;"
  end
end
