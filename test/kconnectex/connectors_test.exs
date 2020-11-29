defmodule Kconnectex.ConnectorsTest do
  use ExUnit.Case, async: true

  alias Kconnectex.Connectors

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

    def call(%{url: "409" <> _}, _) do
      %Tesla.Env{
        status: 409,
        body: nil
      }
    end

    def call(%{url: "localhost/connectors"}, _) do
      %Tesla.Env{
        status: 200,
        body: Jason.encode!(["replicator", "debezium"])
      }
    end

    def call(%{method: :delete, url: "localhost/connectors/debezium"}, _) do
      %Tesla.Env{
        status: 202,
        body: ""
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

    def call(%{url: "localhost/connectors/debezium/status"}, _) do
      %Tesla.Env{
        status: 200,
        body:
          Jason.encode!(%{
            name: "debezium",
            connector: %{
              state: "RUNNING",
              worker_id: "fakehost:8083"
            },
            tasks: [
              %{
                id: 0,
                state: "FAILED",
                worker_id: "fakehost:8083",
                trace: "org.apache.kafka.common.errors.RecordTooLargeException\n"
              }
            ]
          })
      }
    end

    def call(%{method: :post, url: "localhost/connectors/debezium/restart"}, _) do
      %Tesla.Env{
        status: 200,
        body: ""
      }
    end

    def call(%{method: :put, url: "localhost/connectors/debezium/pause"}, _) do
      %Tesla.Env{
        status: 202,
        body: ""
      }
    end

    def call(%{method: :put, url: "localhost/connectors/debezium/resume"}, _) do
      %Tesla.Env{
        status: 202,
        body: ""
      }
    end
  end

  test "GET /connectors" do
    assert Connectors.connectors(client()) == ["replicator", "debezium"]
  end

  test "GET /connectors/:connector" do
    response = Connectors.info(client(), "debezium")

    assert response["name"] == "debezium"
    assert Map.has_key?(response, "config")
    assert Map.has_key?(response, "tasks")
  end

  @tag :skip
  test "GET /connectors/:connector with a bad connector"

  test "GET /connectors/:connector/config" do
    config = Connectors.config(client(), "debezium")

    assert config["connector.class"] == "io.debezium.DebeziumConnector"
  end

  test "GET /connectors/:connector/status" do
    status = Connectors.status(client(), "debezium")

    assert status["name"] == "debezium"
    assert Map.has_key?(status, "connector")
    assert Map.has_key?(status["connector"], "state")
    assert Map.has_key?(status, "tasks")
    assert Map.has_key?(status["tasks"] |> List.first(), "state")
  end

  test "POST /connectors/:connector/restart" do
    assert :ok == Connectors.restart(client(), "debezium")
  end

  test "POST /connectors/:connector/restart when rebalancing" do
    assert {:error, :rebalancing} == Connectors.restart(client("409"), "debezium")
  end

  test "PUT /connectors/:connector/pause" do
    assert :ok == Connectors.pause(client(), "debezium")
  end

  test "PUT /connectors/:connector/pause when rebalancing" do
    assert {:error, :rebalancing} == Connectors.pause(client("409"), "debezium")
  end

  test "PUT /connectors/:connector/resume" do
    assert :ok == Connectors.resume(client(), "debezium")
  end

  test "PUT /connectors/:connector/resume when rebalancing" do
    assert {:error, :rebalancing} == Connectors.resume(client("409"), "debezium")
  end

  test "DELETE /connectors/:connector" do
    assert :ok == Connectors.delete(client(), "debezium")
  end

  test "DELETE /connectors/:connector when rebalancing" do
    assert {:error, :rebalancing} == Connectors.delete(client("409"), "debezium")
  end

  defp client(base_url \\ "localhost") do
    Kconnectex.client(base_url, FakeAdapter)
  end
end
