defmodule AzimuttWeb.Components.Header do
  @moduledoc """
  Header component
  """
  use Phoenix.Component
  import AzimuttWeb.Components.Brand

  @doc "Displays full logo. "
  def header(assigns) do
    ~H"""
    <header class="py-10" x-data="{ open: false }">
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <nav class="relative z-50 flex justify-between">
          <div class="flex items-center md:gap-x-12">
            <a aria-label="Home" href="/">
              <.logo class="h-12 transition-transform duration-300 ease-out transform hover:scale-105" />
            </a>
            <div class="hidden md:flex md:gap-x-6">
              <%= render_slot(@menu) %>
            </div>
          </div>
          <div class="flex items-center gap-x-5 md:gap-x-8">
            <%= render_slot(@right_menu) %>
            <div class="-mr-1 md:hidden">
              <.mobile_navigation />
            </div>
          </div>
        </nav>
        <div x-description="Mobile menu, show/hide based on menu state." class="sm:hidden" id="mobile-menu" x-show="open" style="display: none;">
          <div class="pt-2 pb-3 space-y-1">
            <%= render_slot(@mobile_menu) %>
          </div>
        </div>
      </div>
    </header>
    """
  end

  defp mobile_navigation(assigns) do
    ~H"""
    <button type="button"
      class="inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-indigo-500"
      aria-controls="mobile-menu"
      @click="open = !open"
      aria-expanded="false"
      x-bind:aria-expanded="open.toString()">
        <span class="sr-only">Open main menu</span>
        <svg x-description="Icon when menu is closed. Heroicon name: outline/menu" x-state:on="Menu open" x-state:off="Menu closed" class="h-6 w-6 block" :class="{ 'hidden': open, 'block': !(open) }" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h16"></path>
        </svg>
        <svg x-description="Icon when menu is open. Heroicon name: outline/x" x-state:on="Menu open" x-state:off="Menu closed" class="h-6 w-6 hidden" :class="{ 'block': open, 'hidden': !(open) }" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"></path>
        </svg>
    </button>
    """
  end
end
