defmodule Kconnectex.ConnectorPlugins do
  @moduledoc """
  Endpoint to list loaded connector plugins and validate configuration for a connector plugin.

  https://docs.confluent.io/platform/current/connect/references/restapi.html#connector-plugins
  """

  alias Kconnectex.Request

  @doc """
  Lists installed connector plugins.
  This only checks for plugins on the worker serving the request, so may
  return inconsistent results.

  ## Parameters

    - client: client from `Kconnectex.client/1`

  ## Examples

      > Kconnectex.ConnectorPlugins.list(client)

      {:ok, [
        %{
          "class" => "io.debezium.connector.postgresql.PostgresConnector",
          "type" => "source",
          "version" => "1.3.1.Final"
        }]}
  """
  def list(client) do
    Request.new(client)
    |> Request.get("/connector-plugins")
    |> Request.execute()
  end

  @doc """
  Validates the provided configuration values, returning suggestions and
  errors for each configuration value.

  ## Parameters

    - client: client from `Kconnectex.client/1`
    - config: map of configuration values

  ## Examples

      > config = %{
          "connector.class" => "org.apache.kafka.connect.file.FileStreamSinkConnector",
          "file" => "/kafka/LICENSE",
          "topics" => "license-stream",
          "name" => "license-stream"
        }
      > Kconnectex.ConnectorPlugins.validate_config(client, config)

      {:ok, [
        %{
          "error_count" => 0,
          "name" => "org.apache.kafka.connect.file.FileStreamSinkConnector",
          "groups" => [...],
          "configs" => [...]
        }]}

      > bad_config = Map.delete(config, "name")
      > Kconnectex.ConnectorPlugins.validate_config(client, bad_config)

      {:ok, %{
        "error_count" => 1,
        "configs" => [
          %{
            "definition" => %{
              "required" => true,
              "default_value" => nil,
              "display_name" => "Connector name",
              "documentation" => "Globally unique name to use for this connector.",
              ...
            },
            "value" => %{
              "errors" => ["Missing required configuration \"name\" which has no default value."],
              "name" => "name",
              "value" => nil,
              ...
            },
          },
          ...
        ]
        "name" => "org.apache.kafka.connect.file.FileStreamSinkConnector",
        "groups" => [...],
        "configs" => [...]
      }}
  """
  def validate_config(client, config) when is_map(config) do
    class = connector_class(config)

    Request.new(client)
    |> Request.validate({:present, class}, "config must have key: connector.class")
    |> Request.put("/connector-plugins/#{class}/config/validate", config)
    |> Request.execute()
  end

  defp connector_class(%{"connector.class" => class}) do
    if String.contains?(class, ".") do
      class |> String.split(".", trim: true) |> List.last()
    else
      class
    end
  end

  defp connector_class(_), do: nil
end
