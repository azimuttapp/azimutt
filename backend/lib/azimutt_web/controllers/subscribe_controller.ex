defmodule AzimuttWeb.SubscribeController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts
  alias Azimutt.Organizations
  alias Azimutt.Utils.Result
  action_fallback AzimuttWeb.FallbackController

  def index(conn, %{"plan" => plan_id, "freq" => freq}) do
    current_user = conn.assigns.current_user
    organizations = Organizations.list_organizations(current_user)

    with {:ok, plan} <- Azimutt.plans()[String.to_atom(plan_id)] |> Result.from_nillable(),
         {:ok, price} <- plan[String.to_atom(freq)] |> Result.from_nillable() do
      conn
      |> put_root_layout({AzimuttWeb.LayoutView, "root_organization_new.html"})
      |> render("index.html", plan: plan, freq: freq, price: price, organizations: organizations)
    end
  end
end
