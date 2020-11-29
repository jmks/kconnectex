defmodule Kconnectex.ClusterTest do
  use ExUnit.Case, async: true

  defmodule FakeAdapter do
    def call(%{url: "localhost/"}, _) do
      %Tesla.Env{
        status: 200,
        body:
          Jason.encode!(%{
            "version" => "5.5.0",
            "commit" => "e5741b90cde98052",
            "kafka_cluster_id" => "I4ZmrWqfT2e-upky_4fdPA"
          })
      }
    end

    def call(%{url: "badconn" <> _}, _) do
      {:error, :econnrefused}
    end

    def call(%{url: "badjson" <> _}, _) do
      %Tesla.Env{
        status: 200,
        body: "badjson"
      }
    end
  end

  test "GET /" do
    assert Kconnectex.Cluster.info(client()) == %{
             "version" => "5.5.0",
             "commit" => "e5741b90cde98052",
             "kafka_cluster_id" => "I4ZmrWqfT2e-upky_4fdPA"
           }
  end

  test "GET / with bad JSON" do
    assert {:error, %Jason.DecodeError{}} = Kconnectex.Cluster.info(client("badjson"))
  end

  test "GET / with no connection" do
    assert Kconnectex.Cluster.info(client("badconn")) == {:error, :econnrefused}
  end

  defp client(base_url \\ "localhost") do
    Kconnectex.client(base_url, FakeAdapter)
  end
end
