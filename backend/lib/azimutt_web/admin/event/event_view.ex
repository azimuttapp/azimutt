defmodule AzimuttWeb.Admin.EventView do
  # use AzimuttWeb, :view
  # use Phoenix.View, root: "lib/azimutt_web/admin/templates", path: "*"
  use Phoenix.View, root: "lib/azimutt_web", namespace: AzimuttWeb

  import Phoenix.HTML.Tag
  import Phoenix.HTML.Link
  alias AzimuttWeb.Router.Helpers, as: Routes

  def format_date(date) do
    {:ok, date_parsed} = Timex.format(date, "{D}/{M}/{YY} à {h24}h{m}:{s}")
    date_parsed
  end

  def display_project_name(event) do
    if event.project !== nil do
      content_tag(:div, event.project.name, class: "font-medium")
    else
      " -"
    end
  end

  def display_organization_name(event) do
    if event.organization !== nil do
      event.organization.name
    else
      " - "
    end
  end

  def badge(event_name) do
    default_class = "px-1"

    case event_name do
      event_name when event_name in [:login] ->
        content_tag(:div, event_name, class: default_class <> "text-gray-100")

      event_name when event_name in [:project_updated] ->
        content_tag(:div, event_name, class: default_class <> " text-scheme-blue")

      event_name when event_name in [:project_loaded, :subscribe_init, :subscribe_start, :stripe_subscription_created, :billing_loaded] ->
        content_tag(:div, event_name, class: default_class <> " text-scheme-yellow")

      event_name when event_name in [:project_created, :subscribe_success, :stripe_invoice_paid, :stripe_subscription_renewed] ->
        content_tag(:div, event_name, class: default_class <> " text-scheme-green")

      event_name
      when event_name in [
             :project_deleted,
             :subscribe_error,
             :subscribe_abort,
             :stripe_invoice_payment_failed,
             :stripe_subscription_canceled
           ] ->
        content_tag(:div, event_name, class: default_class <> " text-scheme-red")

      event_name when event_name in [:stripe_subscription_quantity_updated, :stripe_subscription_updated] ->
        content_tag(:div, event_name, class: default_class <> " text-scheme-darkblue")

      event_name ->
        content_tag(:div, event_name, class: default_class <> " text-gray-200")
    end
  end
end
