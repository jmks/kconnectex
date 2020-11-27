defmodule KconnectexTest do
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

    def call(%{url: "badjson/"}, _) do
      %Tesla.Env{
        status: 200,
        body: "badjson"
      }
    end

    def call(%{url: "localhost/connectors"}, _) do
      %Tesla.Env{
        status: 200,
        body: Jason.encode!(["replicator", "debezium"])
      }
    end
  end

  test "GET /" do
    client = Kconnectex.client("localhost", FakeAdapter)

    assert Kconnectex.info(client) == %{
             "version" => "5.5.0",
             "commit" => "e5741b90cde98052",
             "kafka_cluster_id" => "I4ZmrWqfT2e-upky_4fdPA"
           }
  end

  test "GET / with bad JSON" do
    client = Kconnectex.client("badjson", FakeAdapter)

    assert {:error, %Jason.DecodeError{}} = Kconnectex.info(client)
  end

  test "GET /connectors" do
    assert Kconnectex.connectors(client("localhost")) == ["replicator", "debezium"]
  end

  defp client(base) do
    Kconnectex.client(base, FakeAdapter)
  end
end
