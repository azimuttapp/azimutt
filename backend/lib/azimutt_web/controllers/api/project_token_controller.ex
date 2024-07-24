defmodule AzimuttWeb.Api.ProjectTokenController do
  use AzimuttWeb, :controller
  alias Azimutt.Projects
  alias Azimutt.Projects.ProjectToken
  action_fallback AzimuttWeb.Api.FallbackController

  def index(conn, %{"organization_organization_id" => _, "project_project_id" => project_id}) do
    {now, current_user} = {DateTime.utc_now(), conn.assigns.current_user}

    with {:ok, tokens} <- Projects.list_project_tokens(project_id, current_user, now),
         do: conn |> render("index.json", tokens: tokens)
  end

  def create(conn, %{"organization_organization_id" => _, "project_project_id" => project_id} = params) do
    current_user = conn.assigns.current_user

    with {:ok, %ProjectToken{} = _} <- Projects.create_project_token(project_id, current_user, params),
         do: conn |> send_resp(:no_content, "")
  end

  def delete(conn, %{"organization_organization_id" => _, "project_project_id" => _, "token_id" => token_id}) do
    {now, current_user} = {DateTime.utc_now(), conn.assigns.current_user}

    with {:ok, %ProjectToken{} = _} <- Projects.revoke_project_token(token_id, current_user, now),
         do: conn |> send_resp(:no_content, "")
  end
end
