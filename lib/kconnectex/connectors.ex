defmodule Kconnectex.Connectors do
  import Kconnectex.Util

  def connectors(client) do
    handle_response(Tesla.get(client, "/connectors"))
  end

  def info(client, connector) do
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
