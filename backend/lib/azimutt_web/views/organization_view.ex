defmodule AzimuttWeb.OrganizationView do
  use AzimuttWeb, :view

  def last_update(datetime) do
    {:ok, relative_str} = datetime |> Timex.format("{relative}", :relative)
    relative_str
  end

  def generate_html_event_description(event) do
    %{text: text, author: author, destination: destination} = Azimutt.Tracking.event_to_action(event)

    content_tag :div, class: "text-xs" do
      [
        content_tag(:span, " #{author}", class: "font-semibold text-gray-900"),
        content_tag(:span, " #{text}", class: "text-gray-800"),
        content_tag(:span, " #{destination}", class: "font-semibold text-blue-500")
      ]
    end
  end
end
