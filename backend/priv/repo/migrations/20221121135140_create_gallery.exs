defmodule Azimutt.Repo.Migrations.CreateGallery do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :public, :string, default: "none", null: false, comment: "enum: none, read, write"
    end

    create table(:gallery) do
      # FIXME: description is limited to 255 chars :(
      add :project_id, references(:projects)
      add :slug, :string, null: false
      add :icon, :string, null: false
      add :color, :string, null: false
      add :website, :string, null: false, comment: "link for the website of the schema"
      add :banner, :string, null: false, comment: "banner image, 1600x900"
      add :tips, :string, null: false, comment: "shown on project creation"
      add :description, :string, null: false, comment: "shown on list and detail view"
      add :analysis, :text, null: false, comment: "markdown shown on detail view"

      timestamps()
    end

    create unique_index(:gallery, [:slug])
  end
end
