defmodule Azimutt.Services.OpenAI do
  @moduledoc """
  OpenAI service, use to generate SQL query for the moment.
  """
  require Logger
  alias HTTPoison
  alias HTTPoison.Error
  alias HTTPoison.Response
  alias Jason

  @openai_api_key Azimutt.config(:openai_api_key)
  @openai_api_url "https://api.openai.com/v1/completions"

  def generate_sql_query(schema_text, query_asked) do
    prompt = "Generate an SQL query from the following schema: #{schema_text} to respond at the following demand : #{query_asked} "
    make_request(prompt)
  end

  defp make_request(prompt) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{@openai_api_key}"}
    ]

    body =
      %{
        "model" => "text-davinci-003",
        "prompt" => prompt,
        "max_tokens" => 150,
        "top_p" => 1,
        "frequency_penalty" => 0,
        "presence_penalty" => 0,
        "stop" => ["#", ";"],
        "temperature" => 0.7
      }
      |> Jason.encode!()

    case HTTPoison.post(@openai_api_url, body, headers) do
      {:ok, %Response{status_code: 200, body: body}} ->
        handle_response(body)

      {:ok, %Response{status_code: status_code, body: body}} ->
        Logger.error("Error: #{status_code} - #{body}")
        {:error, "Failed to generate SQL query"}

      {:error, %Error{reason: reason}} ->
        Logger.error("Error: #{inspect(reason)}")
        {:error, "Failed to generate SQL query"}
    end
  end

  defp handle_response(body) do
    with {:ok, decoded_body} <- Jason.decode(body),
         %{"choices" => [%{"text" => sql_query}]} <- decoded_body do
      {:ok, String.trim(sql_query)}
    else
      _ ->
        {:error, "Failed to parse response"}
    end
  end
end
