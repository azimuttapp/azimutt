defmodule Azimutt.BlogTest do
  use Azimutt.DataCase
  alias Azimutt.Blog

  describe "blog" do
    test "all articles are valid" do
      assert {:ok, _} = Blog.get_articles()
    end
  end
end
