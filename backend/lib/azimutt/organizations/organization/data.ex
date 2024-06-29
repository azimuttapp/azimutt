defmodule Azimutt.Organizations.Organization.Data do
  @moduledoc false
  use Ecto.Schema

  # see https://hexdocs.pm/ecto/embedded-schemas.html
  @primary_key false
  embedded_schema do
    field :allowed_projects, :integer
    field :allowed_layouts, :integer
    field :allowed_layout_tables, :integer
    field :allowed_memos, :integer
    field :allow_table_color, :string
    # field :allow_table_local_save, :boolean
    field :allow_private_links, :boolean
    field :allow_database_analysis, :boolean
  end
end
