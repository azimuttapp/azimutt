defmodule AzimuttWeb.OrganizationController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts
  alias Azimutt.Organizations
  alias Azimutt.Organizations.Organization
  alias Azimutt.Projects
  alias Azimutt.Utils.Uuid
  action_fallback AzimuttWeb.FallbackController

  def new(conn, _params) do
    current_user = conn.assigns.current_user
    changeset = Organization.create_non_personal_changeset(%Organization{}, current_user)
    logo = Faker.Avatar.image_url()

    conn
    |> put_root_layout({AzimuttWeb.LayoutView, "root_organization_new.html"})
    |> render("new.html", changeset: changeset, logo: logo)
  end

  def create(conn, %{"organization" => organization_params}) do
    current_user = conn.assigns.current_user

    case Organizations.create_non_personal_organization(organization_params, current_user) do
      {:ok, organization} ->
        conn
        |> put_flash(:info, "Organization created successfully.")
        |> redirect(to: Routes.organization_path(conn, :show, organization))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_root_layout({AzimuttWeb.LayoutView, "root_organization_new.html"})
        |> render("new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => organization_id}) do
    current_user = conn.assigns.current_user

    if organization_id == Uuid.zero() do
      organization = Accounts.get_user_default_organization(current_user)
      conn |> redirect(to: Routes.organization_path(conn, :show, organization))
    end

    with {:ok, organization} <- Organizations.get_organization(organization_id, current_user),
         projects = Projects.list_projects(organization, current_user),
         {:ok, plan} <- Organizations.get_organization_plan(organization),
         do: render(conn, "show.html", organization: organization, projects: projects, plan: plan)
  end

  def edit(conn, %{"id" => organization_id}) do
    current_user = conn.assigns.current_user

    if organization_id == Uuid.zero() do
      organization = Accounts.get_user_default_organization(current_user)
      conn |> redirect(to: Routes.organization_path(conn, :edit, organization))
    end

    with {:ok, organization} <- Organizations.get_organization(organization_id, current_user),
         {:ok, plan} <- Organizations.get_organization_plan(organization) do
      changeset = Organization.update_changeset(organization, %{}, current_user)
      render(conn, "edit.html", organization: organization, plan: plan, changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "organization" => organization_attrs}) do
    current_user = conn.assigns.current_user
    {:ok, organization} = Organizations.get_organization(id, current_user)

    case Organizations.update_organization(organization_attrs, organization, current_user) do
      {:ok, organization} ->
        conn
        |> put_flash(:info, "Organization updated successfully.")
        |> redirect(to: Routes.organization_path(conn, :show, organization))

      {:error, %Ecto.Changeset{} = changeset} ->
        with {:ok, plan} <- Organizations.get_organization_plan(organization),
             do: render(conn, "edit.html", organization: organization, plan: plan, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    now = DateTime.utc_now()
    current_user = conn.assigns.current_user
    {:ok, organization} = Organizations.get_organization(id, current_user)
    {:ok, _organization} = Organizations.delete_organization(organization, now)

    conn
    |> put_flash(:info, "Organization deleted successfully.")
    |> redirect(to: Routes.organization_path(conn, :index))
  end
end
