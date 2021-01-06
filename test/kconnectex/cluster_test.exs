defmodule Kconnectex.ClusterTest do
  use ExUnit.Case, async: true

  defmodule FakeAdapter do
    def call(%{url: "localhost/"}, _) do
      {:ok,
       %Tesla.Env{
         status: 200,
         body: %{
           "version" => "5.5.0",
           "commit" => "e5741b90cde98052",
           "kafka_cluster_id" => "I4ZmrWqfT2e-upky_4fdPA"
         }
       }}
    end

    def call(%{url: "badconn" <> _}, _) do
      {:error, :econnrefused}
    end
  end

  test "GET / with no connection" do
    assert Kconnectex.Cluster.info(client("badconn")) == {:error, :econnrefused}
  end

  @tag :integration
  test "GET /" do
    import IntegrationHelpers

    cluster_info = Kconnectex.Cluster.info(connect_client())

    assert cluster_info["version"] == "2.6.0"
    assert Map.has_key?(cluster_info, "commit")
    assert Map.has_key?(cluster_info, "kafka_cluster_id")
  end

  defp client(base_url \\ "localhost") do
    Kconnectex.client(base_url, FakeAdapter)
  end
end
