defmodule Kconnectex.Tasks do
  import Kconnectex.Util

  def list(client, connector) do
    handle_response(Tesla.get(client, "/connectors/#{connector}/tasks"))
  end
end
