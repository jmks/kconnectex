defmodule Kconnectex.ClusterTest do
  use ExUnit.Case, async: true

  alias Kconnectex.Cluster

  defmodule FakeAdapter do
    def call(%{url: "badconn" <> _}, _) do
      {:error, :econnrefused}
    end
  end

  test "GET / with no connection" do
    assert Cluster.info(client("badconn")) == {:error, :econnrefused}
  end

  @tag :integration
  test "GET /" do
    import IntegrationHelpers

    assert Cluster.info(Kconnectex.client("http://0.0.0.0:9999")) ==
             {:error, :econnrefused}

    {:ok, cluster_info} = Cluster.info(connect_client())

    assert Regex.match?(~r|\d+[.]\d+[.]\d+|, cluster_info["version"])
    assert Map.has_key?(cluster_info, "commit")
    assert Map.has_key?(cluster_info, "kafka_cluster_id")
  end

  @tag :integration
  test "GET /health" do
    import IntegrationHelpers

    assert Cluster.health(Kconnectex.client("http://0.0.0.0:9999")) ==
    {:error, :econnrefused}

    {:ok, health} = Cluster.health(connect_client())

    assert health["status"] == "healthy"
    assert health["message"] == "Worker has completed startup and is ready to handle requests."
  end

  defp client(base_url) do
    Kconnectex.client(base_url, FakeAdapter)
  end
end
