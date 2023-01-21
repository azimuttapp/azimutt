defmodule Azimutt.Utils.PageTest do
  use Azimutt.DataCase
  alias Azimutt.Utils.Page
  alias Azimutt.Utils.Page.Info

  describe "page" do
    test "from_params empty" do
      conn = %{request_path: "/", query_params: %{}}
      info = %Info{path: "/", query: conn.query_params, prefix: "", size: 20, page: 1, filters: %{}, sort: []}
      assert info == conn |> Page.from_conn()
    end

    test "from_params full" do
      conn = %{request_path: "/", query_params: %{"size" => "5", "page" => "3", "f-name" => "loic", "sort" => "-admin,name"}}

      info = %Info{
        path: "/",
        query: conn.query_params,
        prefix: "",
        size: 5,
        page: 3,
        filters: %{"name" => "loic"},
        sort: ["-admin", "name"]
      }

      assert info == conn |> Page.from_conn()
    end
  end
end
