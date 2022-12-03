defmodule Azimutt.BlogTest do
  use Azimutt.DataCase
  alias Azimutt.Blog

  describe "blog" do
    test "all articles are valid" do
      assert {:ok, _} = Blog.list_articles()
    end
  end
end
