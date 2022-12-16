defmodule AzimuttWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.
  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use AzimuttWeb, :controller

  # This clause handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(AzimuttWeb.ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(AzimuttWeb.ErrorView)
    |> render("401.html", message: "Unauthorized")
  end

  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(:forbidden)
    |> put_view(AzimuttWeb.ErrorView)
    |> render("403.html", message: "Forbidden")
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(AzimuttWeb.ErrorView)
    |> render("404.html", message: "Not Found")
  end

  def call(conn, {:error, :gone}) do
    conn
    |> put_status(:gone)
    |> put_view(AzimuttWeb.ErrorView)
    |> render("410.html", message: "Gone")
  end

  def call(conn, {:error, message}) do
    conn
    |> put_status(:internal_server_error)
    |> put_view(AzimuttWeb.ErrorView)
    |> render("500.html", message: message)
  end
end
