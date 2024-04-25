defmodule Azimutt.Repo.Migrations.ExtendOnboarding do
  use Ecto.Migration

  def change do
    alter table(:user_profiles) do
      add :phone, :string
      add :industry, :string
    end
  end
end
