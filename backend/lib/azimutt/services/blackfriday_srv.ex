defmodule Azimutt.Services.BlackFridaySrv do
  @moduledoc false

  def should_display? do
    Date.compare(DateTime.utc_now(), ~D[2024-12-03]) == :lt && Azimutt.config(:host) == "azimutt.app"
  end

  def code do
    "BF24"
  end

  def discount do
    50
  end
end
