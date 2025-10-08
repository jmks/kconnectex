defmodule Kconnectex.Cluster do
  @moduledoc """
  Top-level endpoint to a Connect worker.

  https://docs.confluent.io/platform/current/connect/references/restapi.html#kconnect-cluster
  """

  alias Kconnectex.Request

  @doc """
  Displays basic information for the Kafka Connect cluster.

  ## Parameters

    - client: client from `Kconnectex.client/1`

  ## Examples

      > Kconnectex.Cluster.info(client)

      {:ok,
       %{
         "commit" => "62abe01bee039651",
         "kafka_cluster_id" => "DPyXlcLLQqSfvYLLxCKUoQ",
         "version" => "2.6.0"
       }}
  """
  def info(client) do
    Request.new(client)
    |> Request.get("/")
    |> Request.execute()
  end

  @doc """
  Health of Kafka Connect

  ## Parameters

  - client: client from `Kconnectex.client/1`

  ## Examples

  > Kconnectex.Cluster.health(client)

  {:ok,
  %{
    "status" => "healthy",
    "message" => "Worker has completed startup and is ready to handle requests."
  }}
  """
  def health(client) do
    Request.new(client)
    |> Request.get("/health")
    |> Request.execute()
  end
end
