defmodule Kconnectex.ConnectorsTest do
  use ExUnit.Case

  alias Kconnectex.Connectors

  defmodule FakeAdapter do
    def call(%{url: "localhost/connectors", method: :get, query: query}, _)
        when length(query) > 0 do
      body =
        Enum.reduce(query, %{"a" => %{}, "b" => %{}, "c" => %{}}, fn
          {:expand, :info}, body ->
            body
            |> Enum.map(fn {key, value} -> {key, Map.put(value, "info", %{"config" => %{}})} end)
            |> Enum.into(%{})

          {:expand, :status}, body ->
            body
            |> Enum.map(fn {key, value} ->
              status = %{
                "connector" => %{"state" => "RUNNING"},
                "tasks" => [%{"state" => Enum.random(["RUNNING", "PAUSED", "FAILED"])}]
              }

              {key, Map.put(value, "status", status)}
            end)
            |> Enum.into(%{})
        end)

      {:ok, %Tesla.Env{status: 200, body: body}}
    end

    def call(%{url: "localhost/connectors", method: :get}, _) do
      {:ok, %Tesla.Env{status: 200, body: ["a", "b", "c"]}}
    end

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

    def call(%{method: :get, url: "localhost/connectors/snowflake/offsets"}, _) do
      body = %{
        "offsets" => [
          %{
            "partition" => %{
              "kafka_topic" => "table_1",
              "kafka_partition" => 0
            },
            "offset" => %{
              "kafka_offset" => 123
            }
          }
        ]
      }

      {:ok, %Tesla.Env{status: 200, body: body}}
    end
  end

  test "GET /connectors" do
    {:ok, list} = Connectors.list(client())

    assert list == ["a", "b", "c"]
  end

  test "GET /connectors expanding info" do
    {:ok, map} = Connectors.list(client(), expand: :info)

    for connector <- ["a", "b", "c"] do
      assert Map.has_key?(map, connector)
      assert Map.has_key?(map[connector], "info")
      assert Map.has_key?(map[connector]["info"], "config")
    end
  end

  test "GET /connectors expanding status" do
    {:ok, map} = Connectors.list(client(), expand: :status)

    for connector <- ["a", "b", "c"] do
      assert Map.has_key?(map, connector)
      assert Map.has_key?(map[connector], "status")
      assert Map.has_key?(map[connector]["status"]["connector"], "state")

      for task <- map[connector]["status"]["tasks"] do
        assert Map.has_key?(task, "state")
      end
    end
  end

  test "GET /connectors expanding info and status" do
    {:ok, map} = Connectors.list(client(), expand: [:status, :info])

    for connector <- ["a", "b", "c"] do
      assert Map.has_key?(map, connector)

      assert Map.has_key?(map[connector], "info")

      # status
      assert Map.has_key?(map[connector], "status")
      assert Map.has_key?(map[connector]["status"]["connector"], "state")

      for task <- map[connector]["status"]["tasks"] do
        assert Map.has_key?(task, "state")
      end
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

  test "GET /connectors/:connector with blank connector" do
    assert {:error, ["connector can not be blank"]} == Connectors.info(client(), "")
  end

  test "GET /connectors/:connector for an unknown connector" do
    assert {:error, :not_found} == Connectors.info(client(), "unknown")
  end

  test "POST /connectors/:connector/restart when rebalancing" do
    assert {:error, :rebalancing} == Connectors.restart(client("409"), "debezium")
  end

  test "POST /connectors/:connector/restart?includeTasks=true&onlyFailed=false" do
    assert :ok ==
             Connectors.restart(client(), "debezium", include_tasks: true, only_failed: false)
  end

  @tag :integration
  test "create and update a connector" do
    import IntegrationHelpers

    delete_existing_connectors(connect_client(), ["license-stream"])

    bad_config = %{
      "file" => "/usr/share/doc/kafka/LICENSE",
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

    new_config = Map.put(good_config, "file", "/usr/share/doc/kafka/NOTICE")
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

  test "GET /connectors/:connector/offsets" do
    assert {:ok, offsets} = Connectors.offsets(client(), "snowflake")

    assert Map.has_key?(offsets, "offsets")
  end

  defp client(base_url \\ "localhost") do
    Kconnectex.client(base_url, FakeAdapter)
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
