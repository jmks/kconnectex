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
    with %{status: 200, body: body} <- Tesla.get(client, "/"),
         {:ok, response} <- Jason.decode(body) do
      response
    else
      {:error, json_error} ->
        {:error, json_error}

      # TODO: not sure if this can happen
      env ->
        {:error, env}
    end
  end

  def connectors(client) do
    with %{status: 200, body: body} <- Tesla.get(client, "/connectors"),
         {:ok, response} <- Jason.decode(body) do
      response
    end
  end
end
