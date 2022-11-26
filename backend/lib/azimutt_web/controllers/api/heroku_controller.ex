# handle specific Heroku needs for https://elements.heroku.com/addons#data-store-utilities
# see https://devcenter.heroku.com/categories/building-add-ons
# see https://devcenter.heroku.com/articles/building-an-add-on
# see https://devcenter.heroku.com/articles/add-on-single-sign-on
defmodule AzimuttWeb.Api.HerokuController do
  use AzimuttWeb, :controller
  action_fallback AzimuttWeb.Api.FallbackController

  # https://devcenter.heroku.com/articles/building-an-add-on#the-provisioning-request-example-request
  def create(conn, _params) do
    conn |> render("index.json")
  end

  # https://devcenter.heroku.com/articles/building-an-add-on#the-deprovisioning-request-example-request
  def delete(conn, %{"id" => _id} = _params) do
    conn |> render("index.json")
  end
end
