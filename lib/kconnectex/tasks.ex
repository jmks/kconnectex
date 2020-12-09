defmodule Kconnectex.Tasks do
  import Kconnectex.Util

  def list(client, connector) do
    handle_response(Tesla.get(client, "/connectors/#{connector}/tasks"))
  end

  def status(client, connector, task_id) do
    handle_response(Tesla.get(client, "/connectors/#{connector}/tasks/#{task_id}/status"))
  end

  def restart(client, connector, task_id) do
    handle_response(Tesla.post(client, "/connectors/#{connector}/tasks/#{task_id}/restart", ""))
  end
end
