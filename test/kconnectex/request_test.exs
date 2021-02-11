defmodule Kconnectex.RequestTest do
  use ExUnit.Case, async: true

  alias Kconnectex.Request

  defmodule FakeAdapter do
    def call(%{method: :put, url: "localhost/"}, _) do
      {:ok, %Tesla.Env{status: 200, body: %{"kafka_cluster_id" => "abc123"}}}
    end
  end

  describe "validate" do
    test "returns error when value is blank" do
      req = Request.new(client()) |> Request.validate({:present, "   \r\n"}, "can't be blank")

      assert {:error, ["can't be blank"]} == Request.execute(req)
    end

    test "returns error when value's do not match" do
      req = Request.new(client()) |> Request.validate({:match, "elixir", "ruby"}, "must be elixir")

      assert {:error, ["must be elixir"]} == Request.execute(req)
    end

    test "makes a request with valid conditions" do
      req =
        Request.new(client())
        |> Request.validate({:match, "elixir", "elixir"}, "nope")
        |> Request.validate({:present, "elixir"}, "nope")

      assert {:error, err} = Request.execute(req)
      assert String.contains?(err, "HTTP request not provided")
    end
  end

  describe "requests" do
    test "get" do
      req = Request.new(client()) |> Request.get("http://google.com")

      assert req.mfa == {Tesla, :get, ["http://google.com"]}
    end

    test "post" do
      req = Request.new(client()) |> Request.post("http://example.com", "body")

      assert req.mfa == {Tesla, :post, ["http://example.com", "body"]}
    end

    test "put" do
      req = Request.new(client()) |> Request.put("http://example.com", "body")

      assert req.mfa == {Tesla, :put, ["http://example.com", "body"]}
    end
  end

  @tag :integration
  test "requests" do
    import IntegrationHelpers

    delete_existing_connectors(connect_client(), ["license-stream"])

    base_req = Request.new(connect_client())

    assert {:ok, _} = Request.get(base_req, "/") |> Request.execute()

    path = "/connector-plugins/FileStreamSinkConnector/config/validate"
    valid_config = %{
      "connector.class" => "org.apache.kafka.connect.file.FileStreamSinkConnector",
      "file" => "/kafka/LICENSE",
      "topics" => "license-stream",
      "name" => "license-stream"
    }
    assert {:ok, _} = Request.put(base_req, path, valid_config) |> Request.execute()

    body = %{"config" => valid_config, "name" => valid_config["name"]}
    assert {:ok, _} = Request.post(base_req, "/connectors", body) |> Request.execute()
  end

  defp client(base_url \\ "localhost") do
    Kconnectex.client(base_url, FakeAdapter)
  end
end
