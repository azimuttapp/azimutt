defmodule Azimutt.Utils.MarkdownTest do
  use Azimutt.DataCase
  alias Azimutt.Utils.Markdown

  describe "markdown" do
    test "to_html" do
      markdown = """
      # Title

      text with **bold**
      """

      html = """
      <h1 id="title">
      Title</h1>
      <p>
      text with <strong>bold</strong></p>
      """

      assert {:ok, ^html} = markdown |> Markdown.to_html()
    end
  end
end
