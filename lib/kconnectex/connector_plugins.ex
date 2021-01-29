defmodule Kconnectex.ConnectorPlugins do
  import Kconnectex.Util

  def list(client) do
    handle_response(Tesla.get(client, "/connector-plugins"))
  end

  def validate_config(client, config) when is_map(config) do
    class = connector_class(config)

    handle_response(Tesla.put(client, "/connector-plugins/#{class}/config/validate", config))
  end

  defp connector_class(%{"connector.class" => class}) do
    if String.contains?(class, ".") do
      class |> String.split(".", trim: true) |> List.last()
    else
      class
    end
  end
end
