defmodule KconnectexTest do
  use ExUnit.Case, async: true

  defmodule FakeAdapter do
    @debezium_config %{
      "connector.class" => "io.debezium.DebeziumConnector",
      "tasks.max" => "1",
      "rotate.interval.ms" => "10000"
    }

    def call(%{url: "badconn" <> _}, _) do
      {:error, :econnrefused}
    end

    def call(%{url: "badjson" <> _}, _) do
      %Tesla.Env{
        status: 200,
        body: "badjson"
      }
    end

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

    def call(%{url: "localhost/connectors"}, _) do
      %Tesla.Env{
        status: 200,
        body: Jason.encode!(["replicator", "debezium"])
      }
    end

    def call(%{url: "localhost/connectors/debezium"}, _) do
      %Tesla.Env{
        status: 200,
        body:
          Jason.encode!(%{
            name: "debezium",
            config: @debezium_config,
            tasks: [
              %{connector: "debezium-connector", task: 1}
            ]
          })
      }
    end

    def call(%{url: "localhost/connectors/debezium/config"}, _) do
      %Tesla.Env{
        status: 200,
        body: Jason.encode!(@debezium_config)
      }
    end
  end

  test "GET /" do
    assert Kconnectex.info(client()) == %{
             "version" => "5.5.0",
             "commit" => "e5741b90cde98052",
             "kafka_cluster_id" => "I4ZmrWqfT2e-upky_4fdPA"
           }
  end

  test "GET / with bad JSON" do
    assert {:error, %Jason.DecodeError{}} = Kconnectex.info(client("badjson"))
  end

  test "GET / with no connection" do
    assert Kconnectex.info(client("badconn")) == {:error, :econnrefused}
  end

  test "GET /connectors" do
    assert Kconnectex.connectors(client()) == ["replicator", "debezium"]
  end

  test "GET /connectors/:connector" do
    response = Kconnectex.connector(client(), "debezium")

    assert response["name"] == "debezium"
    assert Map.has_key?(response, "config")
    assert Map.has_key?(response, "tasks")
  end

  @tag :skip
  test "GET /connectors/:connector with a bad connector"

  test "GET /connectors/:connector/config" do
    config = Kconnectex.config(client(), "debezium")

    assert config["connector.class"] == "io.debezium.DebeziumConnector"
  end

  defp client(base_url \\ "localhost") do
    Kconnectex.client(base_url, FakeAdapter)
  end
end
