defmodule Kconnectex do
  @moduledoc """
  Documentation for `Kconnectex`.
  """

  def client(url, adapter \\ Tesla.Adapter.Hackney) do
    middleware = [
      {Tesla.Middleware.BaseUrl, url},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers,
       [
         {"accept", "application/json"},
         {"content-type", "application/json"}
       ]}
    ]

    Tesla.client(middleware, adapter)
  end

  def info(client) do
    handle_response(Tesla.get(client, "/"))
  end

  def connectors(client) do
    handle_response(Tesla.get(client, "/connectors"))
  end

  defp handle_response(response) do
    with %{status: 200, body: body} <- response,
         {:ok, json} <- Jason.decode(body) do
      json
    else
      {:error, json_error} -> {:error, json_error}
      env -> {:error, env}
    end
  end
end
