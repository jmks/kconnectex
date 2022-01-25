defmodule Kconnectex.CLI.ConfigFileTest do
  use ExUnit.Case

  alias Kconnectex.CLI.ConfigFile

  test "example is valid" do
    assert {:ok, _} = ConfigFile.load(".kconnectex.json.example")
  end

  test "selected_cluster must match a cluster" do
    assert {:error, reason} = ConfigFile.load(fixture("missing_selected_cluster.json"))

    assert String.contains?(
             ConfigFile.format_error(reason),
             "selected cluster test does not exist"
           )
  end

  test "return error with missing configuration file" do
    assert {:error, :no_configuration_file} = ConfigFile.load(fixture("nonexistant_file.json"))
  end

  test "return error when not a file (:eisdir)" do
    assert {:error, :no_configuration_file} = ConfigFile.load(fixture(""))
  end

  describe "configuration validation" do
    test "host is required" do
      assert {:error, reason} =
               ConfigFile.validate_config(%{"clusters" => %{"local" => %{"port" => 8083}}})

      assert ConfigFile.format_error(reason) == "cluster local must specify a host"

      assert {:error, reason} =
               ConfigFile.validate_config(%{"clusters" => %{"local" => %{"host" => 8083}}})

      assert ConfigFile.format_error(reason) == "cluster local host must be a string"

      assert {:ok, _} =
               ConfigFile.validate_config(%{
                 "clusters" => %{"local" => %{"host" => "localhost"}}
               })
    end

    test "port must be an integer if present" do
      assert {:error, reason} =
               ConfigFile.validate_config(%{
                 "clusters" => %{"local" => %{"host" => "localhost", "port" => "8080"}}
               })

      assert ConfigFile.format_error(reason) == "cluster local port must be an integer"
    end
  end

  defp fixture(filename) do
    Path.join("test/fixtures/config", filename)
  end
end
