defmodule Kconnectex.Cluster do
  import Kconnectex.Util

  def info(client) do
    handle_response(Tesla.get(client, "/"))
  end
end
