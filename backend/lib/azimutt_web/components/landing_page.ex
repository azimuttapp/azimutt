defmodule AzimuttWeb.Components.LandingPage do
  @moduledoc """
  A set of components for use in a landing page.
  """
  use Phoenix.Component

  def hero_section(assigns) do
    assigns =
      assigns
      |> assign_new(:logo_cloud_title, fn -> nil end)
      |> assign_new(:cloud_logo, fn -> nil end)

    ~H"""
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 pt-20 pb-16 text-center lg:pt-32">
      <h1 class="mx-auto max-w-4xl font-display text-5xl font-medium tracking-tight text-slate-900 sm:text-7xl">
        <%= render_slot(@title) %>
      </h1>
      <p class="mx-auto mt-6 max-w-2xl text-lg tracking-tight text-slate-700">
         <%= render_slot(@description) %>
      </p>
      <%= render_slot(@action_buttons) %>
      <%= if @cloud_logo do %>
        <div class="mt-16">
          <.logo_cloud title={@logo_cloud_title} cloud_logo={@cloud_logo} />
        </div>
      <% end %>
    </div>

    """
  end

  def logo_cloud(assigns) do
    assigns =
      assigns
      |> assign_new(:title, fn -> nil end)
      |> assign_new(:cloud_logo, fn -> nil end)

    ~H"""
    <div id="logo-cloud" class="container px-4 mx-auto">
        <p>Open source ❤️</p>
        <p class="font-display text-base text-slate-900">
         and used by developers from top-notch companies
        </p>
      <div class="flex flex-wrap justify-center items-center">
        <%= for logo <- @cloud_logo do %>
          <div class="w-full p-4 w-1/3 md:w-1/6">
            <div class="py-4 lg:py-8">
              <%= render_slot(logo) %>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def testimonial_card(assigns) do
    assigns =
      assigns
      |> assign_new(:title, fn -> nil end)
      |> assign_new(:name, fn -> nil end)
      |> assign_new(:picture_url, fn -> nil end)
      |> assign_new(:text, fn -> nil end)
      |> assign_new(:link, fn -> nil end)

    ~H"""
    <li>
        <a href={@link} target="_blank">
          <figure class="relative rounded-2xl bg-white p-6 shadow-xl shadow-slate-900/10">
              <svg aria-hidden="true" width="105" height="78" class="absolute top-6 left-6 fill-slate-100">
                  <path d="M25.086 77.292c-4.821 0-9.115-1.205-12.882-3.616-3.767-2.561-6.78-6.102-9.04-10.622C1.054 58.534 0 53.411 0 47.686c0-5.273.904-10.396 2.712-15.368 1.959-4.972 4.746-9.567 8.362-13.786a59.042 59.042 0 0 1 12.43-11.3C28.325 3.917 33.599 1.507 39.324 0l11.074 13.786c-6.479 2.561-11.677 5.951-15.594 10.17-3.767 4.219-5.65 7.835-5.65 10.848 0 1.356.377 2.863 1.13 4.52.904 1.507 2.637 3.089 5.198 4.746 3.767 2.41 6.328 4.972 7.684 7.684 1.507 2.561 2.26 5.5 2.26 8.814 0 5.123-1.959 9.19-5.876 12.204-3.767 3.013-8.588 4.52-14.464 4.52Zm54.24 0c-4.821 0-9.115-1.205-12.882-3.616-3.767-2.561-6.78-6.102-9.04-10.622-2.11-4.52-3.164-9.643-3.164-15.368 0-5.273.904-10.396 2.712-15.368 1.959-4.972 4.746-9.567 8.362-13.786a59.042 59.042 0 0 1 12.43-11.3C82.565 3.917 87.839 1.507 93.564 0l11.074 13.786c-6.479 2.561-11.677 5.951-15.594 10.17-3.767 4.219-5.65 7.835-5.65 10.848 0 1.356.377 2.863 1.13 4.52.904 1.507 2.637 3.089 5.198 4.746 3.767 2.41 6.328 4.972 7.684 7.684 1.507 2.561 2.26 5.5 2.26 8.814 0 5.123-1.959 9.19-5.876 12.204-3.767 3.013-8.588 4.52-14.464 4.52Z"></path>
              </svg>
              <blockquote class="relative">
                <p class="text-lg tracking-tight text-slate-900">
                 <%= @text %>
                </p>
              </blockquote>
              <figcaption
                      class="relative mt-6 flex items-center justify-between border-t border-slate-100 pt-6">
                  <div>
                      <div class="font-display text-base text-slate-900"><%= @name %></div>
                      <div class="mt-1 text-sm text-slate-500"><%= @title %></div>
                  </div>
                  <div class="overflow-hidden rounded-full bg-slate-50">
                      <img alt=""
                           src={@picture_url}
                           width="56" height="56"
                           decoding="async"
                           data-nimg="future"
                           class="h-14 w-14 object-cover"
                           loading="lazy"
                           style="color:transparent" />
                  </div>
              </figcaption>
          </figure>
        </a>
    </li>
    """
  end
end
