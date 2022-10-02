defmodule AzimuttWeb.ErrorViewTest do
  use AzimuttWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  @tag :skip
  test "renders 404.html" do
    assert render_to_string(AzimuttWeb.ErrorView, "404.html", []) =~ "Page not found"
  end

  @tag :skip
  test "renders 500.html" do
    assert render_to_string(AzimuttWeb.ErrorView, "500.html", []) == "Internal Server Error"
  end
end
