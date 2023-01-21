defmodule Azimutt.Utils.StringxTest do
  use Azimutt.DataCase
  # alias Azimutt.Heroku.Resource
  alias Azimutt.Utils.Stringx

  describe "string" do
    test "plural" do
      assert "users" = Stringx.plural("user")
    end

    test "pluralize" do
      assert "1 user" = Stringx.pluralize(1, "user")
      assert "2 users" = Stringx.pluralize(2, "user")
    end

    test "inspect" do
      # IO.puts Stringx.inspect(%Resource{}|> cast(%{app: ""}, [:app])|> validate_required([:app]))
    end
  end
end
