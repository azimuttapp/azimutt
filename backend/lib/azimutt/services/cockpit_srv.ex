defmodule Azimutt.Services.CockpitSrv do
  @moduledoc false
  import Ecto.Query, warn: false
  require Logger
  alias Azimutt.Accounts.User
  alias Azimutt.Organizations.Organization
  alias Azimutt.Projects.Project
  alias Azimutt.Repo
  alias Azimutt.Tracking.Event
  alias Azimutt.Utils.Result
  alias Azimutt.Utils.Stringx

  # @base_url "http://localhost:3001"
  @base_url "https://cockpit.azimutt.app"

  def boot_check do
    # TODO: add code version
    post(
      "/api/check",
      %{
        instance: System.fetch_env!("PHX_HOST"),
        environment: Azimutt.config(:environment),
        db:
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
          |> Map.filter(fn {_, val} -> val != nil end),
        config:
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
                file: System.fetch_env!("FILE_STORAGE_ADAPTER"),
                email: System.get_env("EMAIL_ADAPTER"),
                twitter: System.get_env("TWITTER"),
                github: System.get_env("GITHUB"),
                posthog: System.get_env("POSTHOG"),
                bento: System.get_env("BENTO"),
                heroku: System.get_env("HEROKU"),
                stripe: System.get_env("STRIPE")
              }
              |> Map.filter(fn {_, val} -> val != nil end)
          }
          |> Map.filter(fn {_, val} -> val != nil end)
      }
      |> Map.filter(fn {_, val} -> val != nil end)
    )
  end

  def send_event(%Event{} = event) do
    post(
      "/api/events",
      %{
        id: event.id,
        instance: Azimutt.config(:host),
        name: event.name,
        details: event.details || %{},
        createdAt: event.created_at
      }
      |> Map.merge(
        if event.created_by do
          %{
            createdBy: %{
              id: event.created_by.id,
              name: event.created_by.name,
              email: event.created_by.email
            }
          }
        else
          %{}
        end
      )
    )
  end

  defp post(path, body) do
    HTTPoison.post(
      "#{@base_url}#{path}",
      Jason.encode!(body),
      [{"Content-Type", "application/json"}]
    )
    |> Result.flat_map(fn res -> Jason.decode(res.body) end)
  end
end
