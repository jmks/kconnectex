alias Kconnectex.{Cluster, Connectors}

defmodule Helpers do
  def filestream_config(topic \\ "license-stream", file \\ "/kafka/LICENSE") do
    %{
      "connector.class" => "FileStreamSource",
      "topic" => topic,
      "file" => file
    }
  end
end

client = Kconnectex.client("http://0.0.0.0:8083")
