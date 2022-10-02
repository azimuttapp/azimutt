defmodule AzimuttWeb.Storybook.Typography do
  use PhxLiveStorybook.Entry, :page

  def icon, do: "fad fa-text-size"

  def render(assigns) do
    ~H"""
    <main class="justify-center mx-auto max-w-2xl">
      <h1 class="border-b-2 border-slate-200">Titles</h1>

      <div class="ml-4 pb-4">
        <h1>H1 - Lorem ipsum dolor sit amet</h1>
        <h2>H2 - Lorem ipsum dolor sit amet</h2>
        <h3>H3 - Lorem ipsum dolor sit amet</h3>
        <h4>H4 - Lorem ipsum dolor sit amet</h4>
        <h5>H5 - Lorem ipsum dolor sit amet</h5>
      </div>

      <h1 class="border-b-2 border-slate-200">Body text</h1>

      <div class="ml-4 space-y-4 pb-4">
        <p class="text-justify">
          Lorem ipsum dolor sit, amet consectetur adipisicing elit. Excepturi, expedita nihil.
          Rem in totam iusto, aliquid natus voluptates amet possimus dolorem mollitia dolor
          laboriosam eaque beatae, qui, consectetur impedit dolore.
        </p>
        <p class="text-justify italic">
          Lorem ipsum dolor sit, amet consectetur adipisicing elit. Excepturi, expedita nihil.
          Rem in totam iusto, aliquid natus voluptates amet possimus dolorem mollitia dolor
          laboriosam eaque beatae, qui, consectetur impedit dolore.
        </p>
      </div>

      <h1 class="border-b-2 border-slate-200">Font weights</h1>

      <div class="ml-4 pb-4">
        <%= for {weight_class, weight} <- font_weights() do %>
          <p class={"#{weight_class} my-2"}>
            <%= "#{weight_class} - font weight: #{weight}" %>
          </p>
        <% end %>
      </div>
    </main>
    """
  end

  defp font_weights do
    [
      {"font-thin", 100},
      {"font-extralight", 200},
      {"font-light", 300},
      {"font-normal", 400},
      {"font-medium", 500},
      {"font-semibold", 600},
      {"font-bold", 700},
      {"font-extrabold", 800},
      {"font-black", 900}
    ]
  end
end
