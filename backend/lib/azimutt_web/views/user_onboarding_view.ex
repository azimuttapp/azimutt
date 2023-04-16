defmodule AzimuttWeb.UserOnboardingView do
  use AzimuttWeb, :view

  def get_steps(current) do
    steps = ["About you", "Your company", "Azimutt setup", "Our community"]
    index = steps |> Enum.find_index(fn s -> s == current end)

    steps
    |> Enum.with_index(fn s, i ->
      {s,
       cond do
         i < index -> "complete"
         i == index -> "current"
         i > index -> "upcoming"
       end}
    end)
  end

  # like [input_id](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html#input_id/3) but to generate the `for` attribute in labels (don't add form name)
  def input_for(form, field, value) do
    input_id(form, field, value) |> String.replace_prefix("#{form.name}_", "")
  end
end
