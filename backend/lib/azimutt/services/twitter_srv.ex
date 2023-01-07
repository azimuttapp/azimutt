defmodule Azimutt.Services.TwitterSrv do
  @moduledoc false
  alias Azimutt.Utils.Mapx
  alias Azimutt.Utils.Result
  # available API: https://github.com/parroty/extwitter/blob/master/lib/extwitter.ex

  def parse_url(tweet_url) do
    Regex.named_captures(~r/https?:\/\/twitter.com\/(?<user>[^\/]+)\/status\/(?<tweet>[0-9]+).*/, tweet_url)
    |> Result.from_nillable()
    |> Result.map(&Mapx.atomize/1)
  end

  def get_tweet(id) do
    {:ok, ExTwitter.show(id)}
  rescue
    e -> {:error, e}
  end

  # TODO: get_followers(screen_name)

  # see https://github.com/parroty/extwitter/blob/master/lib/extwitter/model.ex
  defmodule Tweet do
    @moduledoc false
    def get_user_name(%ExTwitter.Model.Tweet{} = tweet) do
      tweet.user.screen_name
    end

    def is_after?(%ExTwitter.Model.Tweet{} = tweet, date) do
      Timex.parse(tweet.created_at, "{WDshort} {Mshort} {D} {h24}:{m}:{s} {Z} {YYYY}")
      |> Result.map(fn created_at -> Timex.compare(created_at, date) == 1 end)
      |> Result.or_else(false)
    end

    def has_hashtag?(%ExTwitter.Model.Tweet{} = tweet, hashtag) do
      tweet.entities.hashtags |> Enum.any?(fn h -> h.text == hashtag end)
    end

    def has_mention?(%ExTwitter.Model.Tweet{} = tweet, screen_name) do
      tweet.entities.user_mentions |> Enum.any?(fn u -> u.screen_name == screen_name end)
    end

    def has_url?(%ExTwitter.Model.Tweet{} = tweet, url) do
      tweet.entities.urls |> Enum.any?(fn u -> u.expanded_url |> String.starts_with?(url) end)
    end
  end
end
