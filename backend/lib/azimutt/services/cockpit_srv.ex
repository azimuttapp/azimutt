defmodule Azimutt.Services.CockpitSrv do
  @moduledoc false
  import Ecto.Query, warn: false
  require Logger
  alias Azimutt.Accounts.User
  alias Azimutt.Organizations.Organization
  alias Azimutt.Projects.Project
  alias Azimutt.Repo
  alias Azimutt.Services.CockpitSrv
  alias Azimutt.Services.CockpitSrv.Runner
  alias Azimutt.Tracking.Event
  alias Azimutt.Utils.Result
  alias Azimutt.Utils.Stringx

  def on_boot do
    check(true)
    Runner.start_link()
  end

  def check(startup) do
    # TODO: add code version
    post("/api/licences/check", %{
      instance: Azimutt.config(:host),
      environment: Azimutt.config(:environment),
      licence: Azimutt.config(:licence),
      startup: startup,
      db: db_stats(),
      config: instance_conf()
    })
    |> Result.fold(
      fn _ ->
        unreachable = Azimutt.config(:cockpit_unreachable) || 0

        if unreachable > 3 do
          set_error_message("Unable to reach licence server, please make sure to allow access or #{contact_us()}.")
        else
          Azimutt.set_config(:cockpit_unreachable, unreachable + 1)
        end
      end,
      fn res ->
        Azimutt.set_config(:cockpit_unreachable, 0)
        Azimutt.set_config(:instance_plans, res["plans"])

        cond do
          res["error"] != nil ->
            set_error_message(res["error"])

          res["warning"] != nil ->
            set_warning_message(res["warning"])

          res["status"] != 200 ->
            set_warning_message("Licence server returned <b>status #{res["status"]}</b>, please #{contact_us()}.")

          true ->
            clear_message()
        end
      end
    )
  end

  def send_event(%Event{} = event) do
    full_event = event |> Azimutt.Repo.preload(:organization) |> Azimutt.Repo.preload(:project)

    post("/api/events", %{
      id: event.id,
      instance: Azimutt.config(:host),
      environment: Azimutt.config(:environment),
      name: event.name,
      details: event.details || %{} |> Map.filter(fn {_, val} -> val != nil end),
      entities:
        if(full_event.created_by, do: [user_infos(full_event.created_by)], else: []) ++
          if(full_event.organization, do: [organization_infos(full_event.organization)], else: []) ++
          if(full_event.project, do: [project_infos(full_event.project)], else: []),
      createdAt: event.created_at
    })
  end

  defmodule Runner do
    @moduledoc false
    use GenServer

    def start_link, do: GenServer.start_link(__MODULE__, %{})

    @impl true
    def init(state) do
      :timer.send_interval(60 * 60 * 1000, :work)
      {:ok, state}
    end

    @impl true
    def handle_info(:work, state) do
      CockpitSrv.check(false)
      {:noreply, state}
    end
  end

  defp post(path, body) do
    cond do
      Azimutt.config(:environment) == :test ->
        {:ok, %{status: 200}}

      Azimutt.config(:environment) == :dev && Azimutt.config(:host) == "localhost" && System.get_env("COCKPIT") == "off" ->
        HTTPoison.post("http://localhost:3001#{path}", Jason.encode!(body), [{"Content-Type", "application/json"}])
        |> Result.flat_map(fn res -> Jason.decode(res.body) end)
        |> Result.tap_error(fn err -> Logger.error("CockpitSrv.post: #{Stringx.inspect(err)}") end)

      true ->
        HTTPoison.post("https://cockpit.azimutt.app#{path}", Jason.encode!(body), [{"Content-Type", "application/json"}])
        |> Result.flat_map(fn res -> Jason.decode(res.body) end)
    end
  end

  defp db_stats do
    last_30_days = Timex.now() |> Timex.shift(days: -30)

    %{
      users: User |> Repo.aggregate(:count),
      active_users: Event |> where([e], e.created_at > ^last_30_days) |> select([e], count(e.created_by_id, :distinct)) |> Repo.one(),
      admins: User |> where([u], u.is_admin == true) |> Repo.aggregate(:count),
      organizations: Organization |> Repo.aggregate(:count),
      np_organizations: Organization |> where([o], o.is_personal == false) |> Repo.aggregate(:count),
      active_organizations: Event |> where([e], e.created_at > ^last_30_days) |> select([e], count(e.organization_id, :distinct)) |> Repo.one(),
      projects: Project |> Repo.aggregate(:count),
      active_projects: Event |> where([e], e.created_at > ^last_30_days) |> select([e], count(e.project_id, :distinct)) |> Repo.one(),
      events: Event |> Repo.aggregate(:count),
      first_event: Event |> Repo.aggregate(:min, :created_at),
      last_event: Event |> Repo.aggregate(:max, :created_at),
      monthly_events:
        Event
        |> select([e], {fragment("to_char(?, 'yyyy-mm')", e.created_at), count()})
        |> group_by([e], fragment("to_char(?, 'yyyy-mm')", e.created_at))
        |> order_by([e], fragment("to_char(?, 'yyyy-mm')", e.created_at))
        |> Repo.all()
        |> Map.new()
    }
    |> Map.filter(fn {_, val} -> val != nil end)
  end

  defp instance_conf do
    %{
      public_site: System.get_env("PUBLIC_SITE"),
      skip_onboarding_funnel: System.get_env("SKIP_ONBOARDING_FUNNEL"),
      skip_email_confirmation: System.get_env("SKIP_EMAIL_CONFIRMATION"),
      require_email_confirmation: System.get_env("REQUIRE_EMAIL_CONFIRMATION"),
      require_email_ends_with: System.get_env("REQUIRE_EMAIL_ENDS_WITH"),
      organization_default_plan: System.get_env("ORGANIZATION_DEFAULT_PLAN"),
      global_organization: System.get_env("GLOBAL_ORGANIZATION"),
      global_organization_alone: System.get_env("GLOBAL_ORGANIZATION_ALONE"),
      support: System.get_env("SUPPORT_EMAIL"),
      sender: System.get_env("SENDER_EMAIL"),
      gateway: System.get_env("GATEWAY_URL"),
      auth:
        %{
          password: System.get_env("AUTH_PASSWORD"),
          github: System.get_env("AUTH_GITHUB")
        }
        |> Map.filter(fn {_, val} -> val != nil end),
      service:
        %{
          file: System.get_env("FILE_STORAGE_ADAPTER"),
          email: System.get_env("EMAIL_ADAPTER"),
          twitter: System.get_env("TWITTER"),
          github: System.get_env("GITHUB"),
          posthog: System.get_env("POSTHOG"),
          bento: System.get_env("BENTO"),
          clever_cloud: System.get_env("CLEVER_CLOUD"),
          heroku: System.get_env("HEROKU"),
          stripe: System.get_env("STRIPE")
        }
        |> Map.filter(fn {_, val} -> val != nil end)
    }
    |> Map.filter(fn {_, val} -> val != nil end)
  end

  defp user_infos(%User{} = user) do
    %{
      kind: "users",
      id: user.id,
      name: user.name,
      email: user.email,
      avatar: user.avatar,
      github: user.github_username,
      twitter: user.twitter_username,
      data: if(user.data, do: user.data |> Map.from_struct(), else: nil),
      is_admin: if(user.is_admin, do: true, else: nil),
      created_at: user.created_at
    }
    |> Map.filter(fn {_, val} -> val != nil end)
  end

  defp organization_infos(%Organization{} = org) do
    %{
      kind: "organizations",
      id: org.id,
      name: org.name,
      logo: org.logo,
      github: org.github_username,
      twitter: org.twitter_username,
      data: if(org.data, do: org.data |> Map.from_struct(), else: nil),
      is_personal: if(org.is_personal, do: true, else: nil),
      created_at: org.created_at
    }
    |> Map.filter(fn {_, val} -> val != nil end)
  end

  defp project_infos(%Project{} = project) do
    %{
      kind: "projects",
      id: project.id,
      name: project.name,
      storage: project.storage_kind,
      nb_sources: project.nb_sources,
      nb_tables: project.nb_tables,
      nb_layouts: project.nb_layouts,
      nb_notes: project.nb_notes,
      nb_memos: project.nb_memos,
      created_at: project.created_at,
      updated_at: project.updated_at
    }
  end

  defp contact_us do
    "contact us at <a href=\"mailto:#{Azimutt.config(:azimutt_email)}\" class=\"font-bold underline\">#{Azimutt.config(:azimutt_email)}</a>"
  end

  defp set_error_message(message) do
    Azimutt.set_config(:instance_message_color, "red")
    Azimutt.set_config(:instance_message, message)
  end

  defp set_warning_message(message) do
    Azimutt.set_config(:instance_message_color, "yellow")
    Azimutt.set_config(:instance_message, message)
  end

  defp clear_message do
    Azimutt.set_config(:instance_message_color, nil)
    Azimutt.set_config(:instance_message, nil)
  end
end
