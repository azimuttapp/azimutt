defmodule Azimutt.Services.BentoSrvTest do
  use Azimutt.DataCase
  alias Azimutt.Services.BentoSrv

  describe "BentoSrv" do
    @tag :skip
    test "send_event" do
      event = %{
        email: "user@mail.com",
        type: "test_bento",
        fields: %{name: "User"},
        details: %{demo: 2},
        date: DateTime.utc_now()
      }

      res = BentoSrv.send_event(event)
      IO.puts("res: #{inspect(res)}")
    end
  end
end
