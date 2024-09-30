defmodule Azimutt.Repo.Migrations.CreateUserAuthTokens do
  use Ecto.Migration

  def change do
    create table(:user_auth_tokens, comment: "Tokens allowing to log as the user, useful for API") do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :nb_access, :integer, null: false
      add :last_access, :utc_datetime_usec
      add :expire_at, :utc_datetime_usec
      timestamps(updated_at: false)
      add :deleted_at, :utc_datetime_usec
    end
  end
end
