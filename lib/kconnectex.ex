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

  def connector(client, connector) do
    handle_response(Tesla.get(client, "/connectors/#{connector}"))
  end

  def config(client, connector) do
    handle_response(Tesla.get(client, "/connectors/#{connector}/config"))
  end

  def status(client, connector) do
    handle_response(Tesla.get(client, "/connectors/#{connector}/status"))
  end

  def restart(client, connector) do
    handle_response(Tesla.post(client, "/connectors/#{connector}/restart", ""))
  end

  defp handle_response(response) do
    case response do
      %{status: 200, body: ""} ->
        :ok

      %{status: 200, body: body} ->
        case Jason.decode(body) do
          {:ok, json} -> json
          otherwise -> otherwise
        end

      %{status: 409} ->
        {:error, :rebalancing}

      {:error, err} ->
        {:error, err}

      env ->
        {:error, env}
    end
  end
end
