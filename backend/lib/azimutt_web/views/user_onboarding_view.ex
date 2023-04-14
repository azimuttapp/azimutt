defmodule AzimuttWeb.UserOnboardingView do
  use AzimuttWeb, :view

  # like [input_id](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html#input_id/3) but to generate the `for` attribute in labels (don't add form name)
  def input_for(form, field, value) do
    input_id(form, field, value) |> String.replace_prefix("#{form.name}_", "")
  end
end
