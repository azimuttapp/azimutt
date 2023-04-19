defmodule AzimuttWeb.UserOnboardingController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts
  alias Azimutt.Tracking
  alias Azimutt.Utils.Result
  alias AzimuttWeb.Services.BillingSrv
  alias AzimuttWeb.UserAuth
  action_fallback AzimuttWeb.FallbackController

  # keep actions sorted in onboarding order

  @steps [
    %{id: :welcome, fields: {[], []}},
    %{id: :explore_or_design, fields: {[:usecase], []}},
    %{id: :solo_or_team, fields: {[:usage], []}},
    %{id: :role, fields: {[:role], []}},
    %{id: :about_you, fields: {[:location], [:description]}},
    %{id: :about_your_company, fields: {[:company], [:company_size, :team_organization_id]}},
    %{id: :plan, fields: {[:plan], []}},
    %{id: :discovered_azimutt, fields: {[:discovered_by], []}},
    %{id: :previous_solutions, fields: {[:previously_tried], []}},
    %{id: :keep_in_touch, fields: {[:product_updates], []}},
    %{id: :community, fields: {[], []}},
    %{id: :finalize, fields: {[], []}}
  ]

  def index(conn, _params), do: conn |> redirect(to: Routes.user_onboarding_path(conn, :welcome))

  def welcome(conn, _params), do: conn |> show_step(:welcome)
  def welcome_next(conn, _params), do: conn |> update_step(:welcome, %{})

  def explore_or_design(conn, _params), do: conn |> show_step(:explore_or_design)
  def explore_or_design_next(conn, %{"user_profile" => profile}), do: conn |> update_step(:explore_or_design, profile)

  def solo_or_team(conn, _params), do: conn |> show_step(:solo_or_team)
  def solo_or_team_next(conn, %{"user_profile" => profile}), do: conn |> update_step(:solo_or_team, profile)

  def role(conn, _params), do: conn |> show_step(:role)
  def role_next(conn, %{"user_profile" => profile}), do: conn |> update_step(:role, profile)

  def about_you(conn, _params), do: conn |> show_step(:about_you)
  def about_you_next(conn, %{"user_profile" => profile}), do: conn |> update_step(:about_you, profile)

  def about_your_company(conn, _params), do: conn |> show_step(:about_your_company)
  def about_your_company_next(conn, %{"user_profile" => profile}), do: conn |> update_step(:about_your_company, profile)

  def plan(conn, _params), do: conn |> show_step(:plan)

  def plan_next(conn, %{"user_profile" => profile_params}) do
    current_user = conn.assigns.current_user
    now = DateTime.utc_now()
    id = :plan

    with {:ok, step} <- @steps |> Enum.find(fn s -> s.id == id end) |> Result.from_nillable(),
         {:ok, p} <- Accounts.get_or_create_profile(current_user) do
      Accounts.set_profile(p, profile_params, now, step.fields)
      |> Result.fold(
        fn err -> conn |> render("#{step.id}.html", changeset: err, profile: p) end,
        fn _ ->
          next = @steps |> Enum.drop_while(fn s -> s.id != id end) |> Enum.at(1)
          p.user |> Accounts.set_onboarding(next.id |> Atom.to_string(), now)

          if profile_params["plan"] == "pro" do
            organization_id = p.team_organization_id || Accounts.get_user_default_organization(current_user).id

            conn
            |> BillingSrv.subscribe_pro(
              current_user,
              organization_id,
              Routes.user_onboarding_url(conn, next.id),
              Routes.user_onboarding_url(conn, step.id),
              Routes.user_onboarding_path(conn, step.id)
            )
          else
            conn |> redirect(to: Routes.user_onboarding_path(conn, next.id))
          end
        end
      )
    end
  end

  def discovered_azimutt(conn, _params), do: conn |> show_step(:discovered_azimutt)
  def discovered_azimutt_next(conn, %{"user_profile" => profile}), do: conn |> update_step(:discovered_azimutt, profile)

  def previous_solutions(conn, _params), do: conn |> show_step(:previous_solutions)
  def previous_solutions_next(conn, %{"user_profile" => profile}), do: conn |> update_step(:previous_solutions, profile)

  def keep_in_touch(conn, _params), do: conn |> show_step(:keep_in_touch)
  def keep_in_touch_next(conn, %{"user_profile" => profile}), do: conn |> update_step(:keep_in_touch, profile)

  def community(conn, _params), do: conn |> show_step(:community)
  def community_next(conn, _params), do: conn |> update_step(:community, %{})

  def finalize(conn, _params) do
    current_user = conn.assigns.current_user
    now = DateTime.utc_now()
    Tracking.user_onboarding(current_user, :finalize, %{})

    current_user
    |> Accounts.set_onboarding(nil, now)
    |> Result.map(fn _ -> conn |> UserAuth.redirect_after_login() end)
  end

  def template(conn, %{"template" => template}), do: conn |> render("#{template}.html")

  defp show_step(conn, id) do
    current_user = conn.assigns.current_user
    now = DateTime.utc_now()
    Tracking.user_onboarding(current_user, id, %{})

    with {:ok, step} <- @steps |> Enum.find(fn s -> s.id == id end) |> Result.from_nillable(),
         {:ok, p} <- Accounts.get_or_create_profile(current_user),
         do: conn |> render("#{step.id}.html", changeset: Accounts.change_profile(p, now, step.fields), profile: p)
  end

  defp update_step(conn, id, profile_params) do
    current_user = conn.assigns.current_user
    now = DateTime.utc_now()
    Tracking.user_onboarding(current_user, id, profile_params)

    with {:ok, step} <- @steps |> Enum.find(fn s -> s.id == id end) |> Result.from_nillable(),
         {:ok, p} <- Accounts.get_or_create_profile(current_user) do
      Accounts.set_profile(p, profile_params, now, step.fields)
      |> Result.fold(
        fn err -> conn |> render("#{step.id}.html", changeset: err, profile: p) end,
        fn _ ->
          next = @steps |> Enum.drop_while(fn s -> s.id != id end) |> Enum.at(1)
          p.user |> Accounts.set_onboarding(next.id |> Atom.to_string(), now)
          conn |> redirect(to: Routes.user_onboarding_path(conn, next.id))
        end
      )
    end
  end
end
