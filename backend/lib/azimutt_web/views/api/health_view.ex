defmodule AzimuttWeb.Api.HealthView do
  use AzimuttWeb, :view

  def render("ping.json", _params) do
    %{}
  end

  def render("health.json", params) do
    %{
      logged: params[:user] != nil
    }
  end
end
