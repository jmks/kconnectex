defmodule Kconnectex.Tasks do
  alias Kconnectex.Request

  def list(client, connector) do
    Request.new(client)
    |> with_connector(connector)
    |> Request.get("/connectors/#{connector}/tasks")
    |> Request.execute()
  end

  def status(client, connector, task_id) do
    Request.new(client)
    |> with_connector(connector)
    |> Request.get("/connectors/#{connector}/tasks/#{task_id}/status")
    |> Request.execute()
  end

  def restart(client, connector, task_id) do
    Request.new(client)
    |> with_connector(connector)
    |> Request.post("/connectors/#{connector}/tasks/#{task_id}/restart", "")
    |> Request.execute()
  end

  defp with_connector(req, connector) do
    Request.validate(req, {:present, connector}, "connector can not be blank")
  end
end
