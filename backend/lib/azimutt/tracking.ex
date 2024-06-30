defmodule Azimutt.Tracking do
  @moduledoc "The Tracking context."
  import Ecto.Query, warn: false
  require Logger
  alias Azimutt.Accounts.User
  alias Azimutt.Organizations.Organization
  alias Azimutt.Projects.Project
  alias Azimutt.Repo
  alias Azimutt.Services.BentoSrv
  alias Azimutt.Services.CockpitSrv
  alias Azimutt.Services.OnboardingSrv
  alias Azimutt.Services.PostHogSrv
  alias Azimutt.Tracking.Event
  alias Azimutt.Utils.Nil
  alias Azimutt.Utils.Result

  def get_streak(%User{} = current_user) do
    now = DateTime.utc_now()
    months_ago = Timex.shift(now, months: -4)

    Event
    |> where([e], e.created_by_id == ^current_user.id and e.created_at >= ^months_ago)
    |> select([e], {fragment("to_char(?, 'yyyy-mm-dd')", e.created_at), count(e.id, :distinct)})
    |> group_by([e], fragment("to_char(?, 'yyyy-mm-dd')", e.created_at))
    |> Repo.all()
    |> Result.from_nillable()
    |> Result.map(fn res -> compute_streak(Map.new(res), now, 0) end)
  end

  defp compute_streak(activity, now, streak) do
    if Map.has_key?(activity, Date.to_string(now)) do
      compute_streak(activity, Timex.shift(now, days: -1), streak + 1)
    else
      streak
    end
  end

  def last_used_project(%User{} = current_user) do
    Event
    |> where(
      [e],
      e.created_by_id == ^current_user.id and not is_nil(e.project_id) and
        (e.name == "project_loaded" or e.name == "project_created" or e.name == "project_updated")
    )
    |> order_by([e], desc: e.created_at)
    |> limit(1)
    |> Repo.one()
    |> Result.from_nillable()
  end

  def last_subscribe_start(%User{} = current_user), do: last_user_event(current_user, "subscribe_start")

  defp last_user_event(%User{} = current_user, event_name) do
    Event
    |> where([e], e.created_by_id == ^current_user.id and e.name == ^event_name)
    |> order_by([e], desc: e.created_at)
    |> limit(1)
    |> Repo.one()
    |> Result.from_nillable()
  end

  def recent_organization_events(%Organization{} = organization) do
    allowed_events = [
      "editor_layout_created",
      "editor_layout_deleted",
      "editor_memo_created",
      "editor_memo_deleted",
      "editor_memo_updated",
      "editor_notes_created",
      "editor_notes_deleted",
      "editor_notes_updated",
      "editor_source_added",
      "editor_source_deleted",
      "editor_source_refreshed",
      "project_created",
      "project_deleted",
      "project_loaded",
      "project_updated"
    ]

    Event
    |> where([e], e.organization_id == ^organization.id)
    |> where([e], not is_nil(e.created_by))
    |> where([e], not is_nil(e.project_id))
    |> where([e], e.name in ^allowed_events)
    |> preload(:created_by)
    |> preload(:project)
    |> order_by([e], desc: e.created_at)
    |> limit(10)
    |> Repo.all()
    |> Result.from_nillable()
  end

  def attribution(current_user, details),
    do: create_event("attribution", nil, details, current_user, nil, nil)

  def user_created(%User{} = current_user, method, attribution),
    do:
      create_event(
        "user_created",
        user_data(current_user),
        %{method: method, azimutt_id: current_user.id, attribution: attribution},
        current_user,
        nil,
        nil
      )

  def user_login(%User{} = current_user, method),
    do: create_event("user_login", user_data(current_user), %{method: method}, current_user, nil, nil)

  def user_onboarding(%User{} = current_user, step, data),
    do: create_event("user_onboarding", user_data(current_user), data |> Map.put("step", step), current_user, nil, nil)

  def organization_loaded(%User{} = current_user, %Organization{} = org),
    do: create_event("organization_loaded", org_data(org), nil, current_user, org.id, nil)

  def project_created(%User{} = current_user, %Project{} = project),
    do: create_event("project_created", project_data(project), nil, current_user, project.organization.id, project.id)

  def project_updated(%User{} = current_user, %Project{} = project),
    do: create_event("project_updated", project_data(project), nil, current_user, project.organization.id, project.id)

  def project_deleted(%User{} = current_user, %Project{} = project),
    do: create_event("project_deleted", project_data(project), nil, current_user, project.organization.id, project.id)

  def billing_loaded(%User{} = current_user, %Organization{} = org, source),
    do: create_event("billing_loaded", org_data(org), %{source: source}, current_user, org.id, nil)

  def subscribe_init(%User{} = current_user, %Organization{} = org, plan, freq, price, quantity),
    do: create_event("subscribe_init", org_data(org), %{plan: plan, freq: freq, price: price, quantity: quantity}, current_user, org.id, nil)

  def subscribe_start(%User{} = current_user, %Organization{} = org, plan, freq, price, quantity),
    do: create_event("subscribe_start", org_data(org), %{plan: plan, freq: freq, price: price, quantity: quantity}, current_user, org.id, nil)

  def subscribe_error(%User{} = current_user, %Organization{} = org, plan, freq, price, quantity, %Stripe.Error{} = error),
    do:
      create_event(
        "subscribe_error",
        org_data(org),
        %{plan: plan, freq: freq, price: price, quantity: quantity, error: error.message},
        current_user,
        org.id,
        nil
      )

  def subscribe_success(%User{} = current_user, %Organization{} = org, details),
    do: create_event("subscribe_success", org_data(org), details, current_user, org.id, nil)

  def subscribe_abort(%User{} = current_user, %Organization{} = org),
    do: create_event("subscribe_abort", org_data(org), nil, current_user, org.id, nil)

  def stripe_subscription_created(%Stripe.Event{} = event, %Organization{} = org, subscription_id, status, price, freq, quantity) do
    create_event(
      "stripe_subscription_created",
      stripe_event_data(event),
      %{subscription_id: subscription_id, status: status, price: price, freq: freq, quantity: quantity},
      nil,
      org.id,
      nil
    )
  end

  def stripe_subscription_deleted(%Stripe.Event{} = event, %Organization{} = org, subscription_id, status, price, freq, quantity) do
    create_event(
      "stripe_subscription_deleted",
      stripe_event_data(event),
      %{subscription_id: subscription_id, status: status, price: price, freq: freq, quantity: quantity},
      nil,
      org.id,
      nil
    )
  end

  def stripe_subscription_canceled(%Stripe.Event{} = event, %Organization{} = org, quantity),
    do: create_event("stripe_subscription_canceled", stripe_event_data(event), %{quantity: quantity}, nil, org.id, nil)

  def stripe_subscription_renewed(%Stripe.Event{} = event, %Organization{} = org, quantity),
    do: create_event("stripe_subscription_renewed", stripe_event_data(event), %{quantity: quantity}, nil, org.id, nil)

  def stripe_subscription_quantity_updated(
        %Stripe.Event{} = event,
        %Organization{} = org,
        quantity,
        previous_quantity
      ),
      do:
        create_event(
          "stripe_subscription_quantity_updated",
          stripe_event_data(event),
          %{quantity: quantity, previous_quantity: previous_quantity},
          nil,
          org.id,
          nil
        )

  def stripe_subscription_updated(%Stripe.Event{} = event, %Organization{} = org, previous),
    do: create_event("stripe_subscription_updated", stripe_event_data(event), %{previous: previous}, nil, org.id, nil)

  def stripe_open_billing_portal(%Stripe.Event{} = event, %Organization{} = org),
    do: create_event("stripe_open_billing_portal", stripe_event_data(event), nil, nil, org.id, nil)

  def stripe_invoice_paid(%Stripe.Event{} = event, %Organization{} = org),
    do: create_event("stripe_invoice_paid", stripe_event_data(event), nil, nil, org.id, nil)

  def stripe_invoice_payment_failed(%Stripe.Event{} = event, %Organization{} = org),
    do: create_event("stripe_invoice_payment_failed", stripe_event_data(event), nil, nil, org.id, nil)

  def stripe_unhandled_event(%Stripe.Event{} = event),
    do: create_event("stripe__unhandled__#{event.type}", stripe_event_data(event), stripe_event_details(event), stripe_event_user(event), stripe_event_organization(event), nil)

  def allow_table_color(%User{} = current_user, %Organization{} = org, tweet_url),
    do: create_event("allow_table_color", org_data(org), %{tweet_url: tweet_url}, current_user, org.id, nil)

  def frontend_event(name, details, %User{} = current_user, organization_id, project_id),
    do: create_event(name, nil, details, current_user, organization_id, project_id)

  def frontend_event(name, details, current_user, organization_id, project_id) when is_nil(current_user),
    do: create_event(name, nil, details, current_user, organization_id, project_id)

  # `organization_id` and `project_id` are nullable
  # FIXME: make this async "fire & forget"
  defp create_event(name, data, details, current_user, organization_id, project_id) do
    if Azimutt.Application.env() == :dev, do: Logger.info("Tracking event '#{name}': #{inspect(details)}")

    saved_data = Nil.safe(data, fn v -> if map_size(v) == 0, do: nil, else: v end)
    saved_details = Nil.safe(details, fn v -> if map_size(v) == 0, do: nil, else: v end)

    %Event{}
    |> Event.changeset(%{
      name: name,
      data: saved_data,
      details: saved_details,
      created_by: current_user,
      organization_id: organization_id,
      project_id: project_id
    })
    |> Repo.insert()
    |> Result.tap(fn event ->
      OnboardingSrv.on_event(event)
      CockpitSrv.send_event(event)
      if Azimutt.config(:bento) && event.created_by, do: BentoSrv.send_event(event)
      if Azimutt.config(:posthog) && event.created_by, do: PostHogSrv.send_event(event)
    end)
  end

  defp user_data(%User{} = user) do
    %{
      slug: user.slug,
      name: user.name,
      email: user.email,
      github_username: user.github_username,
      twitter_username: user.twitter_username,
      is_admin: user.is_admin,
      last_signin: user.last_signin,
      created_at: user.created_at,
      data: if(user.data, do: %{attributed_to: user.data.attributed_to}, else: nil)
    }
  end

  defp org_data(%Organization{} = org) do
    %{
      slug: org.slug,
      name: org.name,
      github_username: org.github_username,
      twitter_username: org.twitter_username,
      stripe_customer_id: org.stripe_customer_id,
      is_personal: org.is_personal,
      clever_cloud: if(Ecto.assoc_loaded?(org.clever_cloud_resource) && org.clever_cloud_resource, do: org.clever_cloud_resource.id, else: nil),
      heroku: if(Ecto.assoc_loaded?(org.heroku_resource) && org.heroku_resource, do: org.heroku_resource.id, else: nil),
      members: if(Ecto.assoc_loaded?(org.members), do: org.members |> length, else: nil),
      projects: if(Ecto.assoc_loaded?(org.projects), do: org.projects |> length, else: nil),
      created_at: org.created_at,
      data:
        if org.data do
          %{
            allowed_layouts: org.data.allowed_layouts,
            allowed_memos: org.data.allowed_memos,
            allow_table_color: org.data.allow_table_color,
            allow_private_links: org.data.allow_private_links,
            allow_database_analysis: org.data.allow_database_analysis
          }
        else
          nil
        end
    }
  end

  defp project_data(%Project{} = project) do
    %{
      slug: project.slug,
      name: project.name,
      description: project.description,
      encoding_version: project.encoding_version,
      storage_kind: project.storage_kind,
      file: project.file,
      local_owner: project.local_owner_id,
      nb_sources: project.nb_sources,
      nb_tables: project.nb_tables,
      nb_columns: project.nb_columns,
      nb_relations: project.nb_relations,
      nb_types: project.nb_types,
      nb_comments: project.nb_comments,
      nb_notes: project.nb_notes,
      nb_layouts: project.nb_layouts,
      created_by: project.created_by_id,
      created_at: project.created_at,
      updated_by: project.updated_by_id,
      updated_at: project.updated_at,
      archived_by: project.archived_by_id,
      archived_at: project.archived_at
    }
  end

  defp stripe_event_data(%Stripe.Event{} = event) do
    %{
      id: event.id,
      object: event.object,
      url: stripe_object_url(event),
      type: event.type
    }
  rescue
    _ -> nil
  end

  defp stripe_event_details(%Stripe.Event{} = event) do
    if event.data && event.data[:object] && event.data[:object].id do
      %{
        id: event.data.object.id,
        object: event.data.object.object,
        url: stripe_object_url(event.data.object),
        metadata: event.data.object.metadata
      }
    else
      nil
    end
  rescue
    _ -> nil
  end

  defp stripe_object_url(object) do
    "https://dashboard.stripe.com" <> if(object.livemode, do: "", else: "/test") <> "/#{object.object}s/#{object.id}"
  end

  defp stripe_event_organization(%Stripe.Event{} = event) do
    if event.data && event.data[:object] && event.data[:object].metadata && event.data[:object].metadata["organization_id"] do
      event.data.object.metadata["organization_id"]
    else
      nil
    end
  rescue
    _ -> nil
  end

  defp stripe_event_user(%Stripe.Event{} = _) do
    nil
  end

  def event_to_action(%{name: name, created_by: user, project: project}) do
    project_name = if project, do: project.name, else: "[project deleted]"
    user_name = if user, do: user.name, else: "Someone"
    text = translate_event_name(name)
    %{author: user_name, text: text, destination: project_name}
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp translate_event_name(name) do
    cond do
      name == "editor_layout_created" -> "created a new layout on"
      name == "editor_layout_deleted" -> "deleted a layout on"
      name == "editor_memo_created" -> "created a new memo on"
      name == "editor_memo_deleted" -> "deleted a memo on"
      name == "editor_memo_updated" -> "updated a new memo on "
      name == "editor_notes_created" -> "created a new note on"
      name == "editor_notes_deleted" -> "deleted a note on"
      name == "editor_notes_updated" -> "updated a note on"
      name == "editor_source_added" -> "added a source on"
      name == "editor_source_deleted" -> "deleted a source on"
      name == "editor_source_refreshed" -> "refreshed a source on"
      name == "project_created" -> "created a new project named"
      name == "project_deleted" -> "deleted a project named"
      name == "project_loaded" -> "has consulted"
      name == "project_updated" -> "updated"
      true -> "have done something on"
    end
  end
end
