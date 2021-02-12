defmodule Kconnectex.Cluster do
  @moduledoc """
  Top-level endpoint to a Connect worker.

  https://docs.confluent.io/platform/current/connect/references/restapi.html#kconnect-cluster
  """

  alias Kconnectex.Request

  def info(client) do
    Request.new(client)
    |> Request.get("/")
    |> Request.execute()
  end
end
