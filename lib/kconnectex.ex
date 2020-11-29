defmodule Kconnectex do
  @moduledoc """
  Documentation for `Kconnectex`.
  """

  import Kconnectex.Util

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

  def pause(client, connector) do
    handle_response(Tesla.put(client, "/connectors/#{connector}/pause", ""))
  end

  def resume(client, connector) do
    handle_response(Tesla.put(client, "/connectors/#{connector}/resume", ""))
  end

  def delete(client, connector) do
    handle_response(Tesla.delete(client, "/connectors/#{connector}"))
  end
end
