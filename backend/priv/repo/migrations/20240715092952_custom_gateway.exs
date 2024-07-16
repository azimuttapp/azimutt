defmodule Azimutt.Repo.Migrations.CustomGateway do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add :gateway, :string, comment: "custom gateway for the organization"
    end
  end
end
