defmodule AzimuttWeb.Api.OrganizationController do
  use AzimuttWeb, :controller
  use PhoenixSwagger
  alias Azimutt.Organizations
  alias Azimutt.Organizations.Organization
  alias Azimutt.Services.TwitterSrv
  alias Azimutt.Tracking
  alias Azimutt.Utils.Result
  alias AzimuttWeb.Utils.CtxParams
  alias AzimuttWeb.Utils.SwaggerCommon
  action_fallback AzimuttWeb.Api.FallbackController

  swagger_path :index do
    tag("Organizations")
    summary("List user organizations")
    description("Get the list of all organizations the user is part of.")
    get("/organizations")
    SwaggerCommon.authorization()

    response(200, "OK", Schema.ref(:Organizations))
    response(400, "Client Error")
  end

  def index(conn, params) do
    current_user = conn.assigns.current_user
    ctx = CtxParams.from_params(params)
    organizations = Organizations.list_organizations(current_user)
    conn |> render("index.json", organizations: organizations, current_user: current_user, ctx: ctx)
  end

  def table_colors(conn, %{"organization_organization_id" => organization_id, "tweet_url" => tweet_url}) do
    now = DateTime.utc_now()
    current_user = conn.assigns.current_user

    with {:ok, %Organization{} = organization} <- Organizations.get_organization(organization_id, current_user),
         {:ok, %{user: _tweet_user, tweet: tweet_id}} <-
           TwitterSrv.parse_url(tweet_url) |> Result.map_error(fn _ -> {:bad_request, "Invalid tweet url"} end),
         {:ok, tweet} <- TwitterSrv.get_tweet(tweet_id) |> Result.map_error(fn e -> {:bad_request, e.message} end) do
      errors =
        [
          if(tweet |> TwitterSrv.Tweet.after?(now |> Timex.shift(minutes: -10)), do: nil, else: "Tweet not within the last 10 minutes"),
          if(tweet |> TwitterSrv.Tweet.has_mention?("azimuttapp"), do: nil, else: "Tweet doesn't mention @azimuttapp"),
          if(tweet |> TwitterSrv.Tweet.has_url?("https://azimutt.app"), do: nil, else: "Tweet doesn't link https://azimutt.app")
        ]
        |> Enum.filter(fn e -> e != nil end)

      if errors == [] do
        {:ok, _} = Organizations.allow_table_color(organization, tweet_url)
        Tracking.allow_table_color(current_user, organization, tweet_url)
      end

      conn |> render("table_colors.json", tweet: tweet, errors: errors)
    end
  end

  def swagger_definitions do
    %{
      Organization:
        swagger_schema do
          description("An Organization in Azimutt")

          properties do
            id(:string, "Unique identifier", required: true, example: "0ed17b9f-cb2c-403a-a148-03215b73deb4")
            slug(:string, "Organization slug", required: true, example: "azimutt")
            name(:string, "Organization name", required: true, example: "Azimutt")
            logo(:string, "Organization logo", example: "https://azimutt.app/images/logo_icon_dark.svg")
            description(:string, "Organization description", example: "The best database explorer for any database!")
          end
        end,
      Organizations:
        swagger_schema do
          description("A collection of Organizations")
          type(:array)
          items(Schema.ref(:Organization))
        end
    }
  end
end
