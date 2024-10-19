defmodule Kconnectex.Connectors do
  @moduledoc """
  Endpoint to manage connectors.

  https://docs.confluent.io/platform/current/connect/references/restapi.html#connectors
  """

  alias Kconnectex.Request

  @doc """
  Lists active connectors.

  https://docs.confluent.io/platform/current/connect/references/restapi.html#get--connectors

  ## Parameters

  - client: client from `Kconnectex.client/1`

  ## Options

  - expand: either `:status`, `:info`, or a list of them: `[:info, :status]`

  ## Examples

  > Kconnectex.Connectors.list(client)

  {:ok, ["debezium", "replicator"]}

  > Kconnectex.Connectors.list(client, :status)

  {:ok, %{
    "debezium" => %{
      "status" => %{
        "name" => "debezium",
        "connector" => {
          "state" => "RUNNING",
          "worker_id" => "10.0.0.162:8083"
        },
        "tasks": [
          %{
            "id" => 0,
            "state" => "RUNNING",
            "worker_id" => "10.0.0.162:8083"
          }
        ],
        "type": "sink"
      }
    }
  }}
  """
  def list(client, options \\ []) do
    request_opts = process_expand(options)

    client
    |> Request.new()
    |> Request.get("/connectors", request_opts)
    |> Request.execute()
  end

  def create(client, connector, config) do
    request_with_connector(client, connector)
    |> Request.post("/connectors", %{name: connector, config: config})
    |> Request.execute()
  end

  def info(client, connector) do
    request_with_connector(client, connector)
    |> Request.get("/connectors/#{connector}")
    |> Request.execute()
  end

  def config(client, connector) do
    request_with_connector(client, connector)
    |> Request.get("/connectors/#{connector}/config")
    |> Request.execute()
  end

  def update(client, connector, config) do
    request_with_connector(client, connector)
    |> Request.put("/connectors/#{connector}/config", config)
    |> Request.execute()
  end

  def status(client, connector) do
    request_with_connector(client, connector)
    |> Request.get("/connectors/#{connector}/status")
    |> Request.execute()
  end

  def restart(client, connector) do
    request_with_connector(client, connector)
    |> Request.post("/connectors/#{connector}/restart", "")
    |> Request.execute()
  end

  def pause(client, connector) do
    request_with_connector(client, connector)
    |> Request.put("/connectors/#{connector}/pause", "")
    |> Request.execute()
  end

  def resume(client, connector) do
    request_with_connector(client, connector)
    |> Request.put("/connectors/#{connector}/resume", "")
    |> Request.execute()
  end

  def delete(client, connector) do
    request_with_connector(client, connector)
    |> Request.delete("/connectors/#{connector}")
    |> Request.execute()
  end

  defp process_expand(opts) do
    expand = Keyword.get(opts, :expand, [])
    expand = if is_atom(expand) do
      [expand: expand]
    else
      Enum.map(expand, fn opt -> {:expand, opt} end)
    end

    new_opts = Keyword.delete(opts, :expand)

    if Enum.any?(expand) do
      Keyword.put(new_opts, :query, expand)
    else
      new_opts
    end
  end

  defp request_with_connector(client, connector) do
    client
    |> Request.new()
    |> Request.validate({:present, connector}, "connector can not be blank")
  end
end
