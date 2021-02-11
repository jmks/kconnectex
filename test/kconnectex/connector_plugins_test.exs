defmodule Kconnectex.ConnectorPluginsTest do
  use ExUnit.Case, async: true

  @file_stream_config %{
    "connector.class" => "org.apache.kafka.connect.file.FileStreamSinkConnector",
    "file" => "/kafka/LICENSE",
    "topics" => "license-stream",
    "name" => "license-stream"
  }

  defmodule FakeAdapter do
    def call(%{method: :get, url: "localhost/connector-plugins"}, _) do
      {:ok,
       %Tesla.Env{
         status: 200,
         body: [
           %{
             "name" => "org.apache.kafka.connect.file.FileStreamSinkConnector",
             "type" => "sink",
             "version" => "2.6.0"
           }
         ]
       }}
    end

    def call(
          %{
            method: :put,
            url: "localhost/connector-plugins/FileStreamSinkConnector/config/validate"
          } = req,
          _
        ) do
      request_body = Jason.decode!(req.body)
      errors = if Map.has_key?(request_body, "name"), do: 0, else: 1

      if Map.has_key?(request_body, "topics") do
        {:ok,
         %Tesla.Env{
           status: 200,
           body: %{
             "name" => request_body["connector.class"],
             "configs" => [],
             "error_count" => errors
           }
         }}
      else
        {:ok,
         %Tesla.Env{
           status: 500,
           body: %{
             "error_code" => 500,
             "message" =>
               "org.apache.kafka.common.config.ConfigException: Must configure one of topics or topics.regex"
           }
         }}
      end
    end
  end

  test "GET /connector-plugins" do
    {:ok, [plugin | _]} = Kconnectex.ConnectorPlugins.list(client())

    assert Map.has_key?(plugin, "name")
    assert Map.has_key?(plugin, "type")
    assert Map.has_key?(plugin, "version")
  end

  test "connector.class is required" do
    {:error, ["config must have key: connector.class"]} =
      Kconnectex.ConnectorPlugins.validate_config(client(), %{})
  end

  test "PUT /connector-plugins/:class/config/validate with good config" do
    {:ok, validate} = Kconnectex.ConnectorPlugins.validate_config(client(), @file_stream_config)

    assert Map.has_key?(validate, "name")
    assert Map.has_key?(validate, "error_count")
    assert Map.has_key?(validate, "configs")
  end

  test "PUT /connector-plugins/:class/config/validate with invalid configuration" do
    bad_config = Map.delete(@file_stream_config, "name")

    {:ok, validate} = Kconnectex.ConnectorPlugins.validate_config(client(), bad_config)

    assert validate["error_count"] == 1
  end

  test "PUT /connector-plugins/:class/config/validate with missing configuration" do
    bad_config = Map.delete(@file_stream_config, "topics")

    {:error, invalid} = Kconnectex.ConnectorPlugins.validate_config(client(), bad_config)

    assert invalid["error_code"] == 500
    assert Map.has_key?(invalid, "message")
  end

  @tag :integration
  test "validating config" do
    import IntegrationHelpers

    {:ok, valid} =
      Kconnectex.ConnectorPlugins.validate_config(connect_client(), @file_stream_config)

    assert valid["name"] == "org.apache.kafka.connect.file.FileStreamSinkConnector"
    assert valid["error_count"] == 0

    invalid_config = Map.delete(@file_stream_config, "name")
    {:ok, invalid} = Kconnectex.ConnectorPlugins.validate_config(connect_client(), invalid_config)
    assert invalid["name"] == "org.apache.kafka.connect.file.FileStreamSinkConnector"
    assert invalid["error_count"] == 1

    assert first_config_error(invalid["configs"]) ==
             "Missing required configuration \"name\" which has no default value."

    error_config = Map.delete(@file_stream_config, "topics")
    {:error, error} = Kconnectex.ConnectorPlugins.validate_config(connect_client(), error_config)
    assert error["error_code"] == 500

    assert error["message"] ==
             "org.apache.kafka.common.config.ConfigException: Must configure one of topics or topics.regex"
  end

  defp client(base_url \\ "localhost") do
    Kconnectex.client(base_url, FakeAdapter)
  end

  defp first_config_error(configs) do
    Enum.find_value(configs, fn
      %{"value" => %{"errors" => [error]}} -> error
      _ -> false
    end)
  end
end
