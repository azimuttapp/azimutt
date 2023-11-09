defmodule AzimuttWeb.Components.Brand do
  @moduledoc "Brand component"
  use Phoenix.Component
  alias AzimuttWeb.Router.Helpers, as: Routes

  @doc "Displays full logo. "
  def logo(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "h-10" end)
      |> assign_new(:variant, fn -> nil end)

    ~H"""
    <%= if @variant do %>
      <img class={@class} src={Routes.static_path(@conn, "/images/logo_#{@variant}.svg")} alt="Azimutt Logo" />
    <% else %>
      <img class={@class} src={Routes.static_path(@conn, if(assigns[:dark], do: "/images/logo_light.svg", else: "/images/logo_dark.svg"))} alt="Azimutt Logo" />
    <% end %>
    """
  end

  @doc "Displays just the icon part of the logo"
  def logo_icon(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "h-9 w-9" end)
      |> assign_new(:variant, fn -> nil end)

    ~H"""
    <%= if @variant do %>
      <img class={@class} src={Routes.static_path(@conn, "/images/logo_icon_#{@variant}.svg")} alt="Azimutt Icon"/>
    <% else %>
      <img class={@class <> " block"} src={Routes.static_path(@conn, "/images/logo_icon_dark.svg")} alt="Azimutt Icon"/>
    <% end %>
    """
  end

  @doc "Displays the full logo from cloudinary"
  def logo_for_emails(assigns) do
    ~H"""
    <img height="60" src={Azimutt.config(:logo_url_for_emails)} alt="Azimutt Logo" />
    """
  end
end
