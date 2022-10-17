defmodule Azimutt.Utils.FrontmatterTest do
  use Azimutt.DataCase
  alias Azimutt.Utils.Frontmatter

  describe "frontmatter" do
    test "parse" do
      frontmatter = """
      ---
      title: My title
      desc: "Do: top!"
      tags: aaa, bbb
      ---
      Some body text

      with lines
      """

      result = %{
        "title" => "My title",
        "desc" => "Do: top!",
        "tags" => "aaa, bbb",
        "body" => "Some body text\n\nwith lines"
      }

      assert {:ok, ^result} = Frontmatter.parse(frontmatter)
    end
  end
end
