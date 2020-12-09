alias Kconnectex.{Cluster, Connectors, Tasks}

defmodule Helpers do
  def filestream_config(topic \\ "license-stream", file \\ "/kafka/LICENSE") do
    %{
      "connector.class" => "FileStreamSource",
      "topic" => topic,
      "file" => file
    }
  end

  def clear_connectors(client) do
    client
    |> Kconnectex.Connectors.list
    |> Enum.map(&Kconnectex.Connectors.delete(client, &1))
  end
end

client = Kconnectex.client("http://0.0.0.0:8083")
