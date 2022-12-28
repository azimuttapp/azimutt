defmodule Azimutt.Tracking.Event do
  @moduledoc "The tracking event schema"
  use Ecto.Schema
  use Azimutt.Schema
  import Ecto.Changeset
  alias Azimutt.Accounts.User
  alias Azimutt.Organizations.Organization
  alias Azimutt.Projects.Project

  schema "events" do
    field :name, Ecto.Enum,
      values: [
        :login,
        :project_loaded,
        :project_created,
        :project_updated,
        :project_deleted,
        :billing_loaded,
        :subscribe_init,
        :subscribe_start,
        :subscribe_error,
        :subscribe_success,
        :subscribe_abort,
        :stripe_subscription_created,
        :stripe_subscription_canceled,
        :stripe_subscription_renewed,
        :stripe_subscription_quantity_updated,
        :stripe_subscription_updated,
        :stripe_open_billing_portal,
        :stripe_invoice_paid,
        :stripe_invoice_payment_failed
      ]

    field :data, :map
    field :details, :map
    belongs_to :created_by, User, source: :created_by
    timestamps(updated_at: false)
    belongs_to :organization, Organization
    belongs_to :project, Project
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:name, :data, :details])
    |> put_change(:created_by, attrs.created_by)
    |> put_change(:organization_id, attrs.organization_id)
    |> put_change(:project_id, attrs.project_id)
    |> validate_required([:name, :data, :created_by])
  end
end
