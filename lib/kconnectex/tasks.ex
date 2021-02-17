defmodule Kconnectex.Tasks do
  @moduledoc """
  Endpoint to manage a connector's tasks.

  https://docs.confluent.io/platform/current/connect/references/restapi.html#tasks
  """

  alias Kconnectex.Request

  @doc """
  List tasks for a given connector.

  ## Parameters

    - client: client from `Kconnectex.client/1`
    - connector: name of the connector

  ## Examples

      > Kconnectex.Tasks.list(client, "license-stream")

      {:ok,
       [
         %{
           "config" => %{
             "batch.size" => "2000",
             "file" => "/kafka/LICENCE",
             "task.class" => "org.apache.kafka.connect.file.FileStreamSourceTask",
             "topic" => "license-lines"
           },
           "id" => %{"connector" => "license-stream", "task" => 0}
         }
       ]}
  """
  def list(client, connector) do
    Request.new(client)
    |> with_connector(connector)
    |> Request.get("/connectors/#{connector}/tasks")
    |> Request.execute()
  end

  @doc """
  Get status of a task.

  ## Parameters

    - client: client from `Kconnectex.client/1`
    - connector: name of the connector
    - task_id: task id

  ## Examples

      > Kconnectex.Tasks.status(client, "license-stream", 0)

      {:ok, %{"id" => 0, "state" => "RUNNING", "worker_id" => "172.19.0.4:8083"}}
  """
  def status(client, connector, task_id) do
    Request.new(client)
    |> with_connector(connector)
    |> Request.get("/connectors/#{connector}/tasks/#{task_id}/status")
    |> Request.execute()
  end

  @doc """
  Restart a task.

  ## Parameters

    - client: client from `Kconnectex.client/1`
    - connector: name of the connector
    - task_id: task id

  ## Examples

      > Kconnectex.Tasks.restart(client, "license-stream", 0)

      :ok
  """
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
