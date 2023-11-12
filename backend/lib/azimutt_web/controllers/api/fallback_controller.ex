defmodule AzimuttWeb.Api.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.
  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use AzimuttWeb, :controller
  alias Azimutt.Utils.Result

  # This clause handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(AzimuttWeb.ErrorView)
    # FIXME: better error formatting (cf backend/test/support/data_case.ex:52#errors_on)
    |> render("error.json", changeset: changeset)
  end

  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(:forbidden)
    |> put_view(AzimuttWeb.ErrorView)
    |> render("error.json", format("Forbidden"))
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(AzimuttWeb.ErrorView)
    |> render("error.json", format("Not Found"))
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(AzimuttWeb.ErrorView)
    |> render("error.json", format("Unauthorized"))
  end

  def call(conn, {:error, {status, message}}) do
    conn
    |> put_status(status)
    |> put_view(AzimuttWeb.ErrorView)
    |> render("error.json", format(message))
  end

  def call(conn, {:error, message}) do
    conn
    |> put_status(:internal_server_error)
    |> put_view(AzimuttWeb.ErrorView)
    |> render("error.json", format(message))
  end

  def call(conn, :ok) do
    conn |> send_resp(:no_content, "")
  end

  def call(conn, other) do
    conn
    |> put_status(:internal_server_error)
    |> put_view(AzimuttWeb.ErrorView)
    |> render("error.json", format(other))
  end

  defp format(value) when is_binary(value), do: %{message: value}
  defp format(value) when is_map(value), do: value |> Map.put(:message, as_string(value))
  defp format(value), do: %{message: as_string(value)}

  defp as_string(value) do
    cond do
      is_binary(value) ->
        value

      is_atom(value) ->
        Atom.to_string(value)

      true ->
        Jason.encode(value) |> Result.or_else(inspect(value))
    end
  end
end
