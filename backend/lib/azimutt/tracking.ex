defmodule Azimutt.Tracking do
  @moduledoc "The Tracking context."
  import Ecto.Query, warn: false
  require Logger
  alias Azimutt.Accounts.User
  alias Azimutt.Organizations.Organization
  alias Azimutt.Projects.Project
  alias Azimutt.Repo
  alias Azimutt.Tracking.Event
  alias Azimutt.Utils.Result

  def last_project_loaded(%User{} = current_user) do
    Event
    |> where([e], e.name == :project_loaded and e.created_by_id == ^current_user.id)
    |> order_by([e], desc: e.created_at)
    |> limit(1)
    |> Repo.one()
    |> Result.from_nillable()
  end

  def last_billing_loaded(%Organization{} = org) do
    Event
    |> where([e], e.name == :billing_loaded and e.organization_id == ^org.id)
    |> order_by([e], desc: e.created_at)
    |> preload(:created_by)
    |> limit(1)
    |> Repo.one()
    |> Result.from_nillable()
  end

  def login(%User{} = current_user, method),
    do: create_event(:login, user_data(current_user), %{method: method}, current_user, nil, nil)

  def project_loaded(%User{} = current_user, %Project{} = project),
    do: create_event(:project_loaded, project_data(project), nil, current_user, project.organization.id, project.id)

  def project_created(%User{} = current_user, %Project{} = project),
    do: create_event(:project_created, project_data(project), nil, current_user, project.organization.id, project.id)

  def project_updated(%User{} = current_user, %Project{} = project),
    do: create_event(:project_updated, project_data(project), nil, current_user, project.organization.id, project.id)

  def project_deleted(%User{} = current_user, %Project{} = project),
    do: create_event(:project_deleted, project_data(project), nil, current_user, project.organization.id, project.id)

  def billing_loaded(%User{} = current_user, %Organization{} = org, source),
    do: create_event(:billing_loaded, org_data(org), %{source: source}, current_user, org.id, nil)

  def subscribe_init(%User{} = current_user, %Organization{} = org, price, quantity),
    do: create_event(:subscribe_init, org_data(org), %{price: price, quantity: quantity}, current_user, org.id, nil)

  def subscribe_start(%User{} = current_user, %Organization{} = org, price, quantity),
    do: create_event(:subscribe_start, org_data(org), %{price: price, quantity: quantity}, current_user, org.id, nil)

  def subscribe_error(%User{} = current_user, %Organization{} = org, price, quantity),
    do: create_event(:subscribe_error, org_data(org), %{price: price, quantity: quantity}, current_user, org.id, nil)

  def subscribe_success(%User{} = current_user, %Organization{} = org),
    do: create_event(:subscribe_success, org_data(org), nil, current_user, org.id, nil)

  def subscribe_abort(%User{} = current_user, %Organization{} = org),
    do: create_event(:subscribe_abort, org_data(org), nil, current_user, org.id, nil)

  def stripe_subscription_created(%Stripe.Event{} = event, %Organization{} = org, %User{} = current_user, quantity, subscription_id),
    do:
      create_event(
        :stripe_subscription_created,
        stripe_event_data(event),
        %{quantity: quantity, subscription_id: subscription_id},
        current_user,
        org.id,
        nil
      )

  def stripe_subscription_canceled(%Stripe.Event{} = event, %Organization{} = org, %User{} = current_user, quantity),
    do: create_event(:stripe_subscription_canceled, stripe_event_data(event), %{quantity: quantity}, current_user, org.id, nil)

  def stripe_subscription_renewed(%Stripe.Event{} = event, %Organization{} = org, %User{} = current_user, quantity),
    do: create_event(:stripe_subscription_renewed, stripe_event_data(event), %{quantity: quantity}, current_user, org.id, nil)

  def stripe_subscription_quantity_updated(
        %Stripe.Event{} = event,
        %Organization{} = org,
        %User{} = current_user,
        quantity,
        previous_quantity
      ),
      do:
        create_event(
          :stripe_subscription_quantity_updated,
          stripe_event_data(event),
          %{quantity: quantity, previous_quantity: previous_quantity},
          current_user,
          org.id,
          nil
        )

  def stripe_subscription_updated(%Stripe.Event{} = event, %Organization{} = org, %User{} = current_user, quantity),
    do: create_event(:stripe_subscription_updated, stripe_event_data(event), %{quantity: quantity}, current_user, org.id, nil)

  def stripe_open_billing_portal(%Stripe.Event{} = event, %Organization{} = org, %User{} = current_user),
    do: create_event(:stripe_open_billing_portal, stripe_event_data(event), nil, current_user, org.id, nil)

  def stripe_invoice_paid(%Stripe.Event{} = event, %Organization{} = org, %User{} = current_user),
    do: create_event(:stripe_invoice_paid, stripe_event_data(event), nil, current_user, org.id, nil)

  def stripe_invoice_payment_failed(%Stripe.Event{} = event, %Organization{} = org, %User{} = current_user),
    do: create_event(:stripe_invoice_payment_failed, stripe_event_data(event), nil, current_user, org.id, nil)

  # `organization_id` and `project_id` are nullable
  defp create_event(name, data, details, %User{} = current_user, organization_id, project_id) do
    if Mix.env() == :dev, do: Logger.info("Tracking event '#{name}': #{inspect(details)}")

    %Event{}
    |> Event.changeset(%{
      name: name,
      data: data,
      details: details,
      created_by: current_user,
      organization_id: organization_id,
      project_id: project_id
    })
    |> Repo.insert()
  end

  defp user_data(%User{} = user) do
    %{
      slug: user.slug,
      name: user.name,
      email: user.email,
      company: user.company,
      location: user.location,
      github_username: user.github_username,
      twitter_username: user.twitter_username,
      is_admin: user.is_admin,
      last_signin: user.last_signin,
      created_at: user.created_at
    }
  end

  defp org_data(%Organization{} = org) do
    %{
      slug: org.slug,
      name: org.name,
      contact_email: org.contact_email,
      location: org.location,
      github_username: org.github_username,
      twitter_username: org.twitter_username,
      stripe_customer_id: org.stripe_customer_id,
      stripe_subscription_id: org.stripe_subscription_id,
      is_personal: org.is_personal,
      heroku: if(Ecto.assoc_loaded?(org.heroku_resource) && org.heroku_resource, do: org.heroku_resource.id, else: nil),
      members: if(Ecto.assoc_loaded?(org.members), do: org.members |> length, else: nil),
      projects: if(Ecto.assoc_loaded?(org.projects), do: org.projects |> length, else: nil),
      created_at: org.created_at
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
      type: event.type
    }
  end
end
