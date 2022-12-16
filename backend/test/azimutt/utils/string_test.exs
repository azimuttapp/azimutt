defmodule Azimutt.Utils.StringxTest do
  use Azimutt.DataCase
  alias Azimutt.Heroku.Resource
  alias Azimutt.Utils.Stringx

  describe "string" do
    test "inspect" do
      # IO.puts Stringx.inspect(%Resource{}|> cast(%{app: ""}, [:app])|> validate_required([:app]))
    end
  end
end
