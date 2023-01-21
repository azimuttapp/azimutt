defmodule Azimutt.Repo.Migrations.AddProjectNbMemos do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :nb_memos, :integer, default: 0, null: false
    end
  end
end
