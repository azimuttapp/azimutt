defmodule AzimuttWeb.WebsiteView do
  use AzimuttWeb, :view
  import AzimuttWeb.Components.Brand
  alias Azimutt.Accounts.User
  alias Azimutt.Utils.Enumx
  alias Azimutt.Utils.Result

  def user_organization(%User{} = user, organization_id) do
    user.members
    |> Enum.map(fn m -> m.organization end)
    |> Enum.find(fn o -> o.id == organization_id end)
    |> Result.from_nillable()
  end

  def user_project(%User{} = user, project_id) do
    user.members
    |> Enum.map(fn m -> m.organization end)
    |> Enum.flat_map(fn o ->
      o.projects
      |> Enum.filter(fn p -> p.id == project_id end)
      |> Enum.map(fn p -> {o, p} end)
    end)
    |> Enumx.one()
  end

  # components with nested block

  def comparison_prose(assigns \\ %{}, do: block), do: render_template("comparisons/_prose.html", assigns, block)

  def connector_article(assigns \\ %{}, do: block), do: render_template("connectors/_article.html", assigns, block)

  def doc_prose(assigns \\ %{}, do: block), do: render_template("docs/_prose.html", assigns, block)
  def doc_info(assigns \\ %{}, do: block), do: render_template("docs/_info.html", assigns, block)
  def doc_warning(assigns \\ %{}, do: block), do: render_template("docs/_warning.html", assigns, block)

  defp render_template(template, assigns, block) do
    assigns = assigns |> Map.new() |> Map.put(:inner_content, block)
    AzimuttWeb.WebsiteView.render(template, assigns)
  end
end
