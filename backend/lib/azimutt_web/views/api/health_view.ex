defmodule AzimuttWeb.Api.HealthView do
  use AzimuttWeb, :view
  alias Azimutt.Utils.Mapx
  alias Azimutt.Utils.Result
  alias Ecto.Adapters.SQL

  def render("ping.json", _params) do
    %{}
  end

  def render("health.json", params) do
    is_admin = params[:user] && params[:user].is_admin

    %{
      commit: build_commit(),
      logged: params[:user] != nil,
      database: SQL.query(Azimutt.Repo, "SELECT true;", []) |> Result.map(fn r -> r.rows |> hd() |> hd() end) |> Result.or_else(false),
      config: if(is_admin, do: build_config(), else: nil),
      server_started: if(is_admin, do: Azimutt.config(:server_started), else: nil),
      version: Azimutt.config(:version),
      version_date: Azimutt.config(:version_date)
    }
  end

  defp build_commit do
    %{
      hash: Azimutt.config(:commit_hash),
      message: Azimutt.config(:commit_message),
      date: Azimutt.config(:commit_date)
    }
    |> Mapx.filter(fn {_, v} -> !is_nil(v) end)
  end

  defp build_config do
    # display some conf to admins without revealing any secret
    %{
      environment: Azimutt.config(:environment),
      host: Azimutt.config(:host),
      skip_public_site: Azimutt.config(:skip_public_site),
      skip_onboarding_funnel: Azimutt.config(:skip_onboarding_funnel),
      skip_email_confirmation: Azimutt.config(:skip_email_confirmation),
      require_email_confirmation: Azimutt.config(:require_email_confirmation),
      require_email_ends_with: Azimutt.config(:require_email_ends_with),
      organization_default_plan: Azimutt.config(:organization_default_plan),
      global_organization: Azimutt.config(:global_organization),
      global_organization_alone: Azimutt.config(:global_organization_alone),
      sender_email: Azimutt.config(:sender_email),
      support_email: Azimutt.config(:support_email),
      file_storage: Azimutt.config(:file_storage),
      email_service: Azimutt.config(:email_service),
      auth_password: Azimutt.config(:auth_password),
      auth_github: Azimutt.config(:auth_github),
      auth_google: Azimutt.config(:auth_google),
      auth_linkedin: Azimutt.config(:auth_linkedin),
      auth_twitter: Azimutt.config(:auth_twitter),
      auth_facebook: Azimutt.config(:auth_facebook),
      auth_clever_cloud: Azimutt.config(:auth_clever_cloud),
      auth_heroku: Azimutt.config(:auth_heroku),
      auth_saml: Azimutt.config(:auth_saml),
      sentry: Azimutt.config(:sentry),
      stripe: Azimutt.config(:stripe),
      bento: Azimutt.config(:bento),
      twitter: Azimutt.config(:twitter),
      github: Azimutt.config(:github)
    }
    |> Mapx.filter(fn {_, v} -> !is_nil(v) end)
  end
end
