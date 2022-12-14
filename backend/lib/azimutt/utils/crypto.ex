defmodule Azimutt.Utils.Crypto do
  @moduledoc "Cryptographic functions"

  def md5(input) do
    :crypto.hash(:md5, input) |> Base.encode16(case: :lower)
  end

  def sha1(input) do
    :crypto.hash(:sha, input) |> Base.encode16(case: :lower)
  end
end
