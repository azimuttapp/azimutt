defmodule AzimuttWeb.OrganizationView do
  use AzimuttWeb, :view

  def last_update(datetime) do
    {:ok, relative_str} = datetime |> Timex.format("{relative}", :relative)
    relative_str
  end

  def generate_html_event_description(event) do
    %{text: text, author: author, destination: destination} = Azimutt.Tracking.event_to_action(event)

    raw("""
    <div class="text-xs">
      <span class="font-semibold text-gray-900 "> #{author}</span>
      <span class="text-gray-800"> #{text}</span>
      <span class="font-semibold text-blue-500"> #{destination}</span>
    </div>
    """)
  end
end
