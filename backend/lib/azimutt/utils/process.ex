defmodule Azimutt.Utils.Process do
  @moduledoc "Generic helpers around processes."

  # inspired by https://semaphoreci.com/blog/2016/11/24/how-to-capture-all-errors-returned-by-a-function-call-in-elixir.html
  @doc """
  Launch a function in a separate process and catch errors as Result if it fails.
  ## Examples
      iex> Process.capture(1_000, fn -> "Hello" end)
      {:ok, "Hello"}
  """
  def capture(timeout_ms, callback) do
    Process.flag(:trap_exit, true)
    caller_pid = self()

    {pid, monitor} = spawn_monitor(fn -> caller_pid |> send({__MODULE__, :response, callback.()}) end)

    receive do
      {:DOWN, ^monitor, :process, ^pid, :normal} ->
        receive do
          {__MODULE__, :response, {:ok, value}} -> {:ok, value}
          {__MODULE__, :response, {:error, err}} -> {:error, err}
          {__MODULE__, :response, response} -> {:ok, response}
        end

      {:DOWN, ^monitor, :process, ^pid, reason} ->
        # FIXME: got `:killed` but error is `(Postgrex.Error) database "azimutt_de" does not exist` :(
        {:error, reason}
    after
      timeout_ms ->
        pid |> Process.exit(:kill)
        {:error, {:timeout, timeout_ms}}
    end
  end
end
