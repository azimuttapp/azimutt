defmodule AzimuttWeb.UserSettingsView do
  use AzimuttWeb, :view

  def format_datetime(date) do
    {:ok, formatted} = Timex.format(date, "{Mshort} {D}, {YYYY} at {h24}:{m}")
    formatted
  end
end
