defmodule Azimutt.Utils.PageTest do
  use Azimutt.DataCase
  alias Azimutt.Utils.Page
  alias Azimutt.Utils.Page.Info

  describe "page" do
    test "from_params empty" do
      conn = %{request_path: "/", query_params: %{}}
      info = %Info{path: "/", query: conn.query_params, prefix: nil, size: 20, page: 1}
      assert info == conn |> Page.from_conn()
    end

    test "from_params full" do
      conn = %{request_path: "/", query_params: %{"size" => "5", "page" => "3"}}
      info = %Info{path: "/", query: conn.query_params, prefix: nil, size: 5, page: 3}
      assert info == conn |> Page.from_conn()
    end
  end
end
