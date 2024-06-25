defmodule AzimuttWeb.SubscribeController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts
  alias Azimutt.Organizations
  alias Azimutt.Utils.Result
  action_fallback AzimuttWeb.FallbackController

  def index(conn, %{"plan" => plan_id, "freq" => freq}) do
    current_user = conn.assigns.current_user
    organizations = Organizations.list_organizations(current_user) |> Enum.sort(fn a, b -> org_order(a) < org_order(b) end)

    with {:ok, plan} <- Azimutt.plans()[String.to_atom(plan_id)] |> Result.from_nillable(),
         {:ok, price} <- plan[String.to_atom(freq)] |> Result.from_nillable() do
      conn
      |> put_root_layout({AzimuttWeb.LayoutView, "root_organization_new.html"})
      |> render("index.html", plan: plan, freq: freq, price: price, organizations: organizations)
    end
  end

  defp org_order(o) do
    priority =
      case o.plan do
        "free" -> 1
        "pro" -> 2
        "solo" -> 3
        "team" -> 4
        "enterprise" -> 5
        true -> 0
      end

    "#{priority}-#{o.name}"
  end
end
