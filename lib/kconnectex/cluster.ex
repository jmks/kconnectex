defmodule Kconnectex.Cluster do
  alias Kconnectex.Request

  def info(client) do
    Request.new(client)
    |> Request.get("/")
    |> Request.execute()
  end
end
