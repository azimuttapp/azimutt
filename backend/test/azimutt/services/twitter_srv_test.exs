defmodule Azimutt.Services.TwitterSrvTest do
  use Azimutt.DataCase
  alias Azimutt.Services.TwitterSrv
  alias Azimutt.Services.TwitterSrv.Tweet

  describe "TwitterSrv" do
    test "extract id" do
      assert {:ok, %{user: "loicknuchel", tweet: "1604135251755663361"}} = TwitterSrv.parse_url("https://twitter.com/loicknuchel/status/1604135251755663361")
      assert {:ok, %{user: "loicknuchel", tweet: "1604135251755663361"}} = TwitterSrv.parse_url("https://twitter.com/loicknuchel/status/1604135251755663361?s=20")
      assert {:error, :not_found} = TwitterSrv.parse_url("bad")
    end

    @tag :skip
    test "get_tweet" do
      {:ok, tweet} = TwitterSrv.get_tweet("1603309394250326016")
      assert "azimuttapp" = tweet |> Tweet.get_user_name()
      assert tweet |> Tweet.is_after?(Timex.parse!("2022-12-14", "{YYYY}-{0M}-{D}"))
      assert tweet |> Tweet.has_url?("https://sqlfordevs.io")
      assert tweet |> Tweet.has_mention?("tobias_petry")

      {:ok, tweet} = TwitterSrv.get_tweet("1601135066305921025")
      assert tweet |> Tweet.has_hashtag?("database")
    end
  end
end
