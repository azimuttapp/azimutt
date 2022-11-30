defmodule AzimuttWeb.GalleryControllerTest do
  use AzimuttWeb.ConnCase
  import Azimutt.AccountsFixtures
  import Azimutt.OrganizationsFixtures
  import Azimutt.ProjectsFixtures
  import Azimutt.GalleryFixtures

  test "GET /gallery", %{conn: conn} do
    user = user_fixture()
    organization = organization_fixture(user)
    project = project_fixture(organization, user)
    sample = sample_fixture(project)
    conn = get(conn, Routes.gallery_path(conn, :index))
    assert html_response(conn, 200) =~ "The Database Schema Gallery"
    assert html_response(conn, 200) =~ HtmlEntities.encode(sample.description)
  end

  test "GET /gallery/:id", %{conn: conn} do
    user = user_fixture()
    organization = organization_fixture(user)
    project = project_fixture(organization, user)
    sample = sample_fixture(project)
    conn = get(conn, Routes.gallery_path(conn, :show, sample.slug))
    assert html_response(conn, 200) =~ "#{project.name} database schema"
    assert html_response(conn, 200) =~ sample.analysis |> String.slice(0, 20)
  end
end
