defmodule Azimutt.Services.BlackFridaySrv do
  @moduledoc false

  def should_display? do
    Date.compare(DateTime.utc_now(), ~D[2023-11-30]) == :lt && Azimutt.config(:host) == "azimutt.app"
  end

  def code do
    "BLACKFRIDAY2023"
  end
end
