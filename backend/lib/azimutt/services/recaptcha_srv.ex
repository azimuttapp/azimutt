defmodule Azimutt.Services.RecaptchaSrv do
  @moduledoc false
  alias Azimutt.Utils.Result

  def validate(response) do
    cond do
      !Azimutt.config(:recaptcha) -> :ok
      response == nil -> {:error, "Missing reCAPTCHA response."}
      true -> verify(response) |> Result.flat_map(fn res -> evaluate(res) end)
    end
  end

  # see https://developers.google.com/recaptcha/docs/verify
  defp verify(response) do
    HTTPoison.post(
      "https://www.google.com/recaptcha/api/siteverify",
      {:form, [{"secret", Azimutt.config(:recaptcha_secret_key)}, {"response", response}]},
      [{"Content-Type", "application/json"}]
    )
    |> Result.flat_map(fn res -> Jason.decode(res.body) end)
  end

  defp evaluate(res) do
    error = if(res["error-codes"], do: " Error: #{res["error-codes"] |> Enum.join(", ")}", else: "")

    cond do
      res["success"] != true -> {:error, "Invalid reCAPTCHA token.#{error}"}
      res["action"] != "submit" -> {:error, "Invalid reCAPTCHA action.#{error}"}
      res["hostname"] != Azimutt.config(:host) -> {:error, "Invalid reCAPTCHA host.#{error}"}
      Azimutt.config(:recaptcha_min_score) && res["score"] < Azimutt.config(:recaptcha_min_score) -> {:error, "Too low reCAPTCHA score.#{error}"}
      true -> :ok
    end
  end
end
