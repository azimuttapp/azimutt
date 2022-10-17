defmodule Azimutt.Utils.Resource do
  @moduledoc "Nicely handle Resources to never forget to close them."

  @doc """
  Safely open, use and close a resource
  ## Examples
      iex> Resource.use(fn -> open() end, fn r -> close(r) end, fn r -> use(r) end)
      {:ok, "result"}
  """
  def use(open, close, use) do
    Azimutt.Utils.Process.capture(3_000, fn ->
      try do
        {:ok, resource} = open.()

        try do
          use.(resource)
        after
          close.(resource)
        end
      rescue
        e -> {:error, e}
      catch
        e -> {:error, e}
      end
    end)
  end
end
