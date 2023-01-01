defmodule AzimuttWeb.Api.TrackingController do
  use AzimuttWeb, :controller
  alias Azimutt.Tracking
  alias Azimutt.Utils.Nil
  action_fallback AzimuttWeb.Api.FallbackController

  def create(conn, %{"name" => name} = params) do
    current_user = conn.assigns.current_user
    all_details = params["details"]
    organization_id = all_details |> Nil.safe(fn d -> d["organization_id"] end)
    project_id = all_details |> Nil.safe(fn d -> d["project_id"] end)
    details = all_details |> Map.delete("organization_id") |> Map.delete("project_id")
    Tracking.frontend_event(name, details, current_user, organization_id, project_id)
    conn |> send_resp(:no_content, "")
  end
end
