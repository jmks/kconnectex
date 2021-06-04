defmodule Kconnectex.CLI.ConfigurationTest do
  use ExUnit.Case

  alias Kconnectex.CLI.Configuration

  test "example is valid" do
    assert {:ok, _} = Configuration.load(".kconnectex.json.example")
  end

  test "selected_cluster must match a cluster" do
    assert {:error, reason} = Configuration.load(fixture("missing_selected_cluster.json"))

    assert String.contains?(
             Configuration.format_error(reason),
             "selected cluster test does not exist"
           )
  end

  describe "configuration validation" do
    test "host is required" do
      assert {:error, reason} =
               Configuration.validate_config(%{"clusters" => %{"local" => %{"port" => 8083}}})

      assert Configuration.format_error(reason) == "cluster local must specify a host"

      assert {:error, reason} =
               Configuration.validate_config(%{"clusters" => %{"local" => %{"host" => 8083}}})

      assert Configuration.format_error(reason) == "cluster local host must be a string"

      assert {:ok, _} =
               Configuration.validate_config(%{
                 "clusters" => %{"local" => %{"host" => "localhost"}}
               })
    end

    test "port must be an integer if present" do
      assert {:error, reason} =
               Configuration.validate_config(%{
                 "clusters" => %{"local" => %{"host" => "localhost", "port" => "8080"}}
               })

      assert Configuration.format_error(reason) == "cluster local port must be an integer"
    end
  end

  defp fixture(filename) do
    Path.join("test/fixtures/config", filename)
  end
end
