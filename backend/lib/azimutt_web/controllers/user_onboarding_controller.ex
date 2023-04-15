defmodule AzimuttWeb.UserOnboardingController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts
  alias Azimutt.Utils.Result
  alias AzimuttWeb.Services.BillingSrv
  action_fallback AzimuttWeb.FallbackController

  # keep actions sorted in onboarding order

  def index(conn, _params), do: conn |> redirect(to: Routes.user_onboarding_path(conn, :welcome))

  def welcome(conn, _params), do: conn |> show("welcome.html", fn _, _ -> nil end)
  def welcome_next(conn, _params), do: conn |> update(nil, fn _, _, _ -> :ok end, "welcome.html", :explore_or_design)

  def explore_or_design(conn, _params), do: conn |> show("explore_or_design.html", &Accounts.change_profile_usecase(&1, &2))

  def explore_or_design_next(conn, %{"usecase" => usecase}),
    do: conn |> update(usecase, &Accounts.set_profile_usecase(&1, &2, &3), "explore_or_design.html", :solo_or_team)

  def solo_or_team(conn, _params), do: conn |> show("solo_or_team.html", &Accounts.change_profile_usage(&1, &2))

  def solo_or_team_next(conn, %{"usage" => usage}),
    do: conn |> update(usage, &Accounts.set_profile_usage(&1, &2, &3), "solo_or_team.html", :role)

  def role(conn, _params), do: conn |> show("role.html", &Accounts.change_profile_role(&1, &2))
  def role_next(conn, %{"role" => role}), do: conn |> update(role, &Accounts.set_profile_role(&1, &2, &3), "role.html", :about_you)

  def about_you(conn, _params), do: conn |> show("about_you.html", &Accounts.change_profile_user_attrs(&1, &2))

  def about_you_next(conn, %{"user_profile" => profile}),
    do: conn |> update(profile, &Accounts.set_profile_user_attrs(&1, &2, &3), "about_you.html", :about_your_company)

  def about_your_company(conn, _params), do: conn |> show("about_your_company.html", &Accounts.change_profile_company(&1, &2))

  def about_your_company_next(conn, %{"user_profile" => profile}),
    do: conn |> update(profile, &Accounts.set_profile_company(&1, &2, &3), "about_your_company.html", :plan)

  def plan(conn, _params), do: conn |> render("plan.html")

  def plan_next(conn, %{"plan" => plan}) do
    current_user = conn.assigns.current_user
    now = DateTime.utc_now()

    Accounts.get_or_create_profile(current_user)
    |> Result.flat_map(fn p ->
      Accounts.set_profile_plan(p, %{plan: plan}, now)
      |> Result.fold(
        fn err -> conn |> render("plan.html", changeset: err, profile: p) end,
        fn _ ->
          current = :plan
          next = :before_azimutt
          p.user |> Accounts.set_onboarding(next |> Atom.to_string(), now)

          if plan == "pro" do
            organization_id = p.team_organization_id || Accounts.get_user_default_organization(current_user).id

            conn
            |> BillingSrv.subscribe_pro(
              current_user,
              organization_id,
              Routes.user_onboarding_url(conn, next),
              Routes.user_onboarding_url(conn, current),
              Routes.user_onboarding_path(conn, current)
            )
          else
            conn |> redirect(to: Routes.user_onboarding_path(conn, next))
          end
        end
      )
    end)
  end

  def before_azimutt(conn, _params), do: conn |> show("before_azimutt.html", &Accounts.change_profile_previous(&1, &2))

  def before_azimutt_next(conn, %{"user_profile" => profile}),
    do: conn |> update(profile, &Accounts.set_profile_previous(&1, &2, &3), "before_azimutt.html", :community)

  def community(conn, _params), do: conn |> render("community.html")
  def community_next(conn, _params), do: conn |> redirect(to: Routes.user_onboarding_path(conn, :finalize))

  def finalize(conn, _params) do
    current_user = conn.assigns.current_user
    now = DateTime.utc_now()

    current_user
    |> Accounts.set_onboarding(nil, now)
    |> Result.map(fn _ -> conn |> redirect(to: Routes.user_dashboard_path(conn, :index)) end)
  end

  def template(conn, %{"template" => template}), do: conn |> render("#{template}.html")

  defp show(conn, template, changeset) do
    current_user = conn.assigns.current_user
    now = DateTime.utc_now()

    Accounts.get_or_create_profile(current_user)
    |> Result.map(fn p -> conn |> render(template, changeset: changeset.(p, now), profile: p) end)
  end

  defp update(conn, value, set, template, next) do
    current_user = conn.assigns.current_user
    now = DateTime.utc_now()

    Accounts.get_or_create_profile(current_user)
    |> Result.flat_map(fn p ->
      set.(p, value, now)
      |> Result.fold(
        fn err -> conn |> render(template, changeset: err, profile: p) end,
        fn _ ->
          p.user |> Accounts.set_onboarding(next |> Atom.to_string(), now)
          conn |> redirect(to: Routes.user_onboarding_path(conn, next))
        end
      )
    end)
  end
end
