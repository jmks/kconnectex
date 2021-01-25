defmodule Kconnectex.ConnectorPluginsTest do
  use ExUnit.Case, async: true

  defmodule FakeAdapter do
    def call(%{method: :get, url: "localhost/connector-plugins"}, _) do
      {:ok,
       %Tesla.Env{
         status: 200,
         body: [
           %{
             "class" => "org.apache.kafka.connect.file.FileStreamSinkConnector",
             "type" => "sink",
             "version" => "2.6.0"
           }
         ]
       }}
    end
  end

  test "GET /connector-plugins" do
    [plugin | _] = Kconnectex.ConnectorPlugins.list(client())

    assert Map.has_key?(plugin, "class")
    assert Map.has_key?(plugin, "type")
    assert Map.has_key?(plugin, "version")
  end

  defp client(base_url \\ "localhost") do
    Kconnectex.client(base_url, FakeAdapter)
  end
end
