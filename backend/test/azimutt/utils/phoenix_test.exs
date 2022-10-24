defmodule Azimutt.Utils.PhoenixTest do
  use Azimutt.DataCase
  alias Azimutt.Utils.Phoenix

  describe "phoenix" do
    test "has_digest" do
      false = Phoenix.has_digest("/path/to/file.md")
      true = Phoenix.has_digest("/path/to/file-d3be962ac0fc1164623927ceebde32cd.md")
    end
  end
end
