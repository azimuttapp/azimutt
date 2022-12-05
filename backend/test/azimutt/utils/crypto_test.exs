defmodule Azimutt.Utils.CryptoTest do
  use Azimutt.DataCase
  alias Azimutt.Utils.Crypto

  describe "crypto" do
    test "sha1" do
      assert "2ef7bde608ce5404e97d5f042f95f89f1c232871" = Crypto.sha1("Hello World!")
    end
  end
end
