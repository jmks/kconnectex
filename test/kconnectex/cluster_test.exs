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

    assert cluster_info["version"] == "3.0.0"
    assert Map.has_key?(cluster_info, "commit")
    assert Map.has_key?(cluster_info, "kafka_cluster_id")
  end

  defp client(base_url) do
    Kconnectex.client(base_url, FakeAdapter)
  end
end
