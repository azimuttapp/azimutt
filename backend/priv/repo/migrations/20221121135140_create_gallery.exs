defmodule Azimutt.Repo.Migrations.CreateGallery do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :visibility, :string, default: "none", null: false, comment: "enum: none, read, write"
    end

    create table(:gallery) do
      add :project_id, references(:projects), null: false
      add :slug, :string, null: false
      add :icon, :string, null: false
      add :color, :string, null: false
      add :website, :string, null: false, comment: "link for the website of the schema"
      add :banner, :string, null: false, comment: "banner image, 1600x900"
      add :tips, :text, null: false, comment: "shown on project creation"
      add :description, :text, null: false, comment: "shown on list and detail view"
      add :analysis, :text, null: false, comment: "markdown shown on detail view"

      timestamps()
    end

    create unique_index(:gallery, [:project_id])
    create unique_index(:gallery, [:slug])
  end
end
