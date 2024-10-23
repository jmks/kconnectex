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

  @doc """
  Restarts a connector. Can optionally restart the connector's tasks or only those that are FAILED.

  https://docs.confluent.io/platform/current/connect/references/restapi.html#post--connectors-(string-name)-restart

  ## Parameters

  - client: client from `Kconnectex.client/1`
  - connector: the connector name

  ## Options

  - expand: either `:status`, `:info`, or a list of them: `[:info, :status]`

  - include_tasks (boolean, default: false): also restart the tasks
  - only_failed (boolean, default: false): only restart the connector (and optionally tasks) that are FAILED

  ## Examples

  > Kconnectex.Connectors.restart(client, "debezium")

  :ok

  > Kconnectex.Connectors.restart(client, "debezium", include_tasks: true, only_failed: true)

  :ok
  """
  def restart(client, connector, options \\ []) do
    opts =
      options
      |> process(:include_tasks, :exclude, :query)
      |> process(:only_failed, :exclude, :query)

    request_with_connector(client, connector)
    |> Request.post("/connectors/#{connector}/restart", "", opts)
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

  def process(options, opt, :exclude, :query) do
    if Keyword.has_key?(options, opt) do
      value = Keyword.fetch!(options, opt)

      options
      |> Keyword.delete(opt)
      |> Keyword.update(:query, [{opt, value}], fn old -> Keyword.put(old, opt, value) end)
    else
      options
    end
  end

  defp request_with_connector(client, connector) do
    client
    |> Request.new()
    |> Request.validate({:present, connector}, "connector can not be blank")
  end
end
