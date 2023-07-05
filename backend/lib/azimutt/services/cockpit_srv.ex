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

  def boot_check do
    # TODO: add code version
    post(
      "/api/check",
      %{
        instance: Azimutt.config(:host),
        environment: Azimutt.config(:environment),
        db: db_stats(),
        config: instance_conf()
      }
      |> Map.filter(fn {_, val} -> val != nil end)
    )

    Runner.start_link()
  end

  def server_up do
    send_event(%Event{
      id: Ecto.UUID.generate(),
      name: "server_up",
      details: %{},
      created_by: nil,
      created_at: DateTime.utc_now()
    })
  end

  def send_event(%Event{} = event) do
    post(
      "/api/events",
      %{
        id: event.id,
        instance: Azimutt.config(:host),
        environment: Azimutt.config(:environment),
        name: event.name,
        details:
          %{organization_id: event.organization_id, project_id: event.project_id}
          |> Map.merge(event.details || %{})
          |> Map.filter(fn {_, val} -> val != nil end),
        createdAt: event.created_at
      }
      |> Map.merge(if(event.created_by, do: %{createdBy: user_infos(event.created_by)}, else: %{}))
    )
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
      CockpitSrv.server_up()
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
    %{
      users: User |> Repo.aggregate(:count),
      admins: User |> where([u], u.is_admin == true) |> Repo.aggregate(:count),
      organizations: Organization |> Repo.aggregate(:count),
      np_organizations: Organization |> where([o], o.is_personal == false) |> Repo.aggregate(:count),
      projects: Project |> Repo.aggregate(:count),
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
end
