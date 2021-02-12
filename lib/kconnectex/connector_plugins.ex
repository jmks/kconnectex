defmodule Kconnectex.ConnectorPlugins do
  @moduledoc """
  Endpoint to list loaded connector plugins and validate configuration for a connector plugin.

  https://docs.confluent.io/platform/current/connect/references/restapi.html#connector-plugins
  """

  alias Kconnectex.Request

  def list(client) do
    Request.new(client)
    |> Request.get("/connector-plugins")
    |> Request.execute()
  end

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
