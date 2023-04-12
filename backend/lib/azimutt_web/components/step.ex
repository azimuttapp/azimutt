defmodule AzimuttWeb.Components.Step do
  @moduledoc "Step component"
  use Phoenix.Component

  @doc "Displays step for a process. "
  def step(assigns) do
    assigns =
      assigns
      |> assign_new(:steps, fn -> [] end)
      |> assign_new(:extra_assigns, fn ->
        assigns_to_attributes(assigns, [
          :steps
        ])
      end)

    ~H"""
    <div class="flex-col justify-center hidden pl-4 sm:flex sm:pl-6 lg:pl-8">
      <nav class="flex justify-center px-6 border-r sm:px-8 lg:px-10 border-gray-900/10" aria-label="Progress">
        <ol role="list" class="space-y-6">
          <%= for {label, state} <- @steps do %>
            <li>
              <div class="flex items-start">
                <.custom_step
                  state={state}
                  label={label}
                />
              </div>
            </li>
          <% end %>
        </ol>
      </nav>
    </div>
    """
  end

  defp custom_step(%{state: "upcoming"} = assigns) do
    ~H"""
    <div class="relative flex items-center justify-center flex-shrink-0 w-5 h-5" aria-hidden="true">
      <div class="w-2 h-2 bg-gray-300 rounded-full"></div>
    </div>
    <p class="ml-3 text-sm font-medium text-gray-500"><%= @label %></p>
    """
  end

  defp custom_step(%{state: "current"} = assigns) do
    ~H"""
    <div class="relative flex items-center justify-center flex-shrink-0 w-5 h-5" aria-hidden="true">
      <div class="absolute w-4 h-4 bg-gray-200 rounded-full"></div>
      <div class="relative block w-2 h-2 bg-gray-600 rounded-full"></div>
    </div>
    <p class="ml-3 text-sm font-medium text-gray-600"><%= @label %></p>
    """
  end

  defp custom_step(%{state: "complete"} = assigns) do
    ~H"""
    <div class="relative flex items-center justify-center flex-shrink-0 w-5 h-5" aria-hidden="true">
      <svg class="w-full h-full text-gray-600" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z" clip-rule="evenodd" />
      </svg>
    </div>
    <p class="ml-3 text-sm font-medium text-gray-500"><%= @label %></p>
    """
  end
end
