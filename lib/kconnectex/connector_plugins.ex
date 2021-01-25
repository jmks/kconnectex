defmodule Kconnectex.ConnectorPlugins do
  import Kconnectex.Util

  def list(client) do
    handle_response(Tesla.get(client, "/connector-plugins"))
  end
end
