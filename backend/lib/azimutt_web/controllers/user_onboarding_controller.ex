defmodule AzimuttWeb.UserOnboardingController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts
  action_fallback AzimuttWeb.FallbackController

  # keep actions sorted in onboarding order

  def index(conn, _params), do: conn |> redirect(to: Routes.user_onboarding_path(conn, :welcome))

  def welcome(conn, _params), do: conn |> render("welcome.html")
  def welcome_next(conn, _params), do: conn |> redirect(to: Routes.user_onboarding_path(conn, :solo_or_team))

  def solo_or_team(conn, _params), do: conn |> render("solo_or_team.html")
  def solo_or_team_next(conn, _params), do: conn |> redirect(to: Routes.user_onboarding_path(conn, :explore_or_design))

  def explore_or_design(conn, _params), do: conn |> render("explore_or_design.html")
  def explore_or_design_next(conn, _params), do: conn |> redirect(to: Routes.user_onboarding_path(conn, :role))

  def role(conn, _params), do: conn |> render("role.html")
  def role_next(conn, _params), do: conn |> redirect(to: Routes.user_onboarding_path(conn, :about_you))

  def about_you(conn, _params), do: conn |> render("about_you.html")
  def about_you_next(conn, _params), do: conn |> redirect(to: Routes.user_onboarding_path(conn, :about_your_company))

  def about_your_company(conn, _params), do: conn |> render("about_your_company.html")
  def about_your_company_next(conn, _params), do: conn |> redirect(to: Routes.user_onboarding_path(conn, :plan))

  def plan(conn, _params), do: conn |> render("plan.html")
  def plan_next(conn, _params), do: conn |> redirect(to: Routes.user_onboarding_path(conn, :before_azimutt))

  def before_azimutt(conn, _params), do: conn |> render("before_azimutt.html")
  def before_azimutt_next(conn, _params), do: conn |> redirect(to: Routes.user_onboarding_path(conn, :community))

  def community(conn, _params), do: conn |> render("community.html")
  def community_next(conn, _params), do: conn |> redirect(to: Routes.user_onboarding_path(conn, :finalize))

  def finalize(conn, _params), do: conn |> redirect(to: Routes.user_dashboard_path(conn, :index))

  def template(conn, %{"template" => template}), do: conn |> render("#{template}.html")
end
