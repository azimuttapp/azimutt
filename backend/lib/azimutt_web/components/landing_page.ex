defmodule AzimuttWeb.Components.LandingPage do
  @moduledoc "A set of components for use in a landing page."
  use Phoenix.Component

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
        <a href={@link} target="_blank" rel="noopener">
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
