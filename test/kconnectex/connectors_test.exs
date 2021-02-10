defmodule Kconnectex.ConnectorsTest do
  use ExUnit.Case

  alias Kconnectex.Connectors

  defmodule FakeAdapter do
    def call(%{url: "409" <> _}, _) do
      {:ok, %Tesla.Env{status: 409, body: nil}}
    end

    def call(%{method: :post, url: "localhost/connectors", body: body}, _) do
      request_body = Jason.decode!(body)

      env =
        if Map.has_key?(request_body["config"], "connector.class") do
          %Tesla.Env{
            status: 200,
            body:
              Map.put(request_body, "tasks", [%{"connector" => request_body["name"], "task" => 1}])
          }
        else
          %Tesla.Env{
            status: 400,
            body: %{
              "error_code" => 400,
              "message" => "Connector config {name=, topic=, file=} contains no connector type"
            }
          }
        end

      {:ok, env}
    end

    def call(%{url: "localhost/connectors/unknown"}, _) do
      {:ok, %Tesla.Env{status: 404, body: ""}}
    end

    def call(%{method: :post, url: "localhost/connectors/debezium/restart"}, _) do
      {:ok, %Tesla.Env{status: 200, body: ""}}
    end

    def call(%{method: :put, url: "localhost/connectors/debezium/pause"}, _) do
      {:ok, %Tesla.Env{status: 202, body: ""}}
    end

    def call(%{method: :put, url: "localhost/connectors/debezium/resume"}, _) do
      {:ok, %Tesla.Env{status: 202, body: ""}}
    end
  end

  test "POST /connectors" do
    config = %{
      "connector.class" => "FileStreamSource",
      "file" => "some-file.txt",
      "topic" => "some-topic"
    }

    {:ok, response} = Connectors.create(client(), "something-new", config)

    assert response["name"] == "something-new"
    assert response["config"] == config
    assert Map.has_key?(response, "tasks")
  end

  test "POST /connectors with missing config" do
    config = %{
      "file" => "some-file.txt",
      "topic" => "some-topic"
    }

    response = Connectors.create(client(), "something-new", config)

    assert {:error, body} = response
    assert body["error_code"] == 400
    assert String.ends_with?(body["message"], "contains no connector type")
  end

  test "GET /connectors/:connector for an unknown connector" do
    assert {:error, :not_found} == Connectors.info(client(), "unknown")
  end

  test "POST /connectors/:connector/restart when rebalancing" do
    assert {:error, :rebalancing} == Connectors.restart(client("409"), "debezium")
  end

  test "PUT /connectors/:connector/pause when rebalancing" do
    assert {:error, :rebalancing} == Connectors.pause(client("409"), "debezium")
  end

  test "PUT /connectors/:connector/resume when rebalancing" do
    assert {:error, :rebalancing} == Connectors.resume(client("409"), "debezium")
  end

  test "DELETE /connectors/:connector when rebalancing" do
    assert {:error, :rebalancing} == Connectors.delete(client("409"), "debezium")
  end

  @tag :integration
  test "create and update a connector" do
    import IntegrationHelpers

    delete_existing_connectors(connect_client(), ["license-stream"])

    bad_config = %{
      "file" => "/kafka/LICENSE",
      "topic" => "license-stream",
      "name" => "license-stream"
    }

    {:error, body} = Connectors.create(connect_client(), "license-stream", bad_config)
    assert body["error_code"] == 400
    assert String.ends_with?(body["message"], "contains no connector type")

    good_config = Map.put(bad_config, "connector.class", "FileStreamSource")
    {:ok, response} = Connectors.create(connect_client(), "license-stream", good_config)
    assert is_map(response)
    assert response["name"] == "license-stream"
    assert response["config"] == good_config
    assert Map.has_key?(response, "tasks")

    assert is_connector?(connect_client(), "license-stream")

    {:ok, info} = Connectors.info(connect_client(), "license-stream")
    assert is_map(info)
    assert info["name"] == "license-stream"
    assert Map.has_key?(info, "config")
    assert Map.has_key?(info, "tasks")

    new_config = Map.put(good_config, "file", "/kafka/NOTICE")
    {:ok, response} = Connectors.update(connect_client(), "license-stream", new_config)
    assert Map.has_key?(response, "config")
    assert Map.has_key?(response, "tasks")

    {:ok, config} = Connectors.config(connect_client(), "license-stream")
    assert config == new_config

    {:ok, status} = Connectors.status(connect_client(), "license-stream")
    assert status["name"] == "license-stream"
    assert Map.has_key?(status, "connector")
    assert Map.has_key?(status["connector"], "state")
    assert Map.has_key?(status, "tasks")
    assert Map.has_key?(status["tasks"] |> hd, "state")

    assert :ok == Connectors.delete(connect_client(), "license-stream")
    refute is_connector?(connect_client(), "license-stream")
  end

  test "POST /connectors/:connector/restart" do
    assert :ok == Connectors.restart(client(), "debezium")
  end

  test "PUT /connectors/:connector/pause" do
    assert :ok == Connectors.pause(client(), "debezium")
  end

  test "PUT /connectors/:connector/resume" do
    assert :ok == Connectors.resume(client(), "debezium")
  end

  defp client(base_url \\ "localhost") do
    Kconnectex.client(base_url, FakeAdapter)
  end

  defp delete_existing_connectors(client, connectors) do
    to_delete = MapSet.new(connectors)

    {:ok, connectors} = Connectors.list(client)

    connectors
    |> Enum.filter(&MapSet.member?(to_delete, &1))
    |> Enum.map(&Connectors.delete(client, &1))
  end

  defp is_connector?(client, name) do
    case Connectors.list(client) do
      {:ok, connectors} ->
        Enum.member?(connectors, name)

      _ ->
        false
    end
  end
end
