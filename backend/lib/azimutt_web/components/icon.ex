defmodule AzimuttWeb.Components.Icon do
  @moduledoc "Icon components"
  use Phoenix.Component

  def check_circle(assigns) do
    ~H"""
    <svg aria-hidden="true" class={"h-6 w-6 flex-none fill-current stroke-current #{@class}"}>
      <path d="M9.307 12.248a.75.75 0 1 0-1.114 1.004l1.114-1.004ZM11 15.25l-.557.502a.75.75 0 0 0 1.15-.043L11 15.25Zm4.844-5.041a.75.75 0 0 0-1.188-.918l1.188.918Zm-7.651 3.043 2.25 2.5 1.114-1.004-2.25-2.5-1.114 1.004Zm3.4 2.457 4.25-5.5-1.187-.918-4.25 5.5 1.188.918Z" stroke-width="0"></path>
      <circle cx="12" cy="12" r="8.25" fill="none" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"></circle>
    </svg>
    """
  end
end
