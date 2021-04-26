alias Kconnectex.{Admin, Cluster, ConnectorPlugins, Connectors, Tasks}

defmodule Helpers do
  def filestream_config(topic \\ "license-stream", file \\ "/kafka/LICENSE") do
    %{
      "connector.class" => "FileStreamSource",
      "topic" => topic,
      "file" => file
    }
  end

  def clear_connectors(client) do
    {:ok, connectors} = Kconnectex.Connectors.list(client)

    Enum.map(connectors, &Kconnectex.Connectors.delete(client, &1))
  end

  def statuses(client) do
    {:ok, connectors} = Kconnectex.Connectors.list(client)

    Enum.each(connectors, fn conn ->
      IO.puts(String.duplicate("=", String.length(conn)))
      IO.puts(conn)
      String.duplicate("=", String.length(conn))
      {:ok, status} = Connectors.status(client, conn)
      IO.inspect(status)
    end)
  end
end

client = Kconnectex.client("http://0.0.0.0:8083")
