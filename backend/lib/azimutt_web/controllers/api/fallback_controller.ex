defmodule AzimuttWeb.Api.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.
  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use AzimuttWeb, :controller

  # This clause handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(AzimuttWeb.ErrorView)
    # FIXME: better error formatting (cf backend/test/support/data_case.ex:52#errors_on)
    |> render("error.json", changeset: changeset)
  end

  # This clause is an example of how to handle resources that cannot be found.
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(AzimuttWeb.ErrorView)
    |> render("error.json", message: "Not Found")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(AzimuttWeb.ErrorView)
    |> render("error.json", message: "Unauthorized")
  end

  def call(conn, {:error, {status, message}}) do
    conn
    |> put_status(status)
    |> put_view(AzimuttWeb.ErrorView)
    |> render("error.json", message: message)
  end

  def call(conn, {:error, message}) do
    conn
    |> put_status(:internal_server_error)
    |> put_view(AzimuttWeb.ErrorView)
    |> render("error.json", message: message)
  end

  def call(conn, :ok) do
    conn |> send_resp(:no_content, "")
  end
end
