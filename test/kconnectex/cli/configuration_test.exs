defmodule Kconnectex.CLI.ConfigurationTest do
  use ExUnit.Case

  alias Kconnectex.CLI.Configuration

  test "example is valid" do
    assert {:ok, _} = Configuration.load(".kconnectex.toml.example")
  end

  test "selected_env must be present" do
    assert {:error, reason} = Configuration.load(fixture("missing_selected_env.toml"))

    assert String.contains?(
             Configuration.format_error(reason),
             "oranges does not exist as table [env.oranges]"
           )
  end

  describe "configuration validation" do
    test "host is required" do
      assert {:error, reason} =
               Configuration.validate_config(%{"env" => %{"local" => %{"port" => 8083}}})

      assert Configuration.format_error(reason) == "host is required"

      assert {:error, reason} =
               Configuration.validate_config(%{"env" => %{"local" => %{"host" => 8083}}})

      assert Configuration.format_error(reason) == "host must be a string"

      assert {:ok, _} =
               Configuration.validate_config(%{"env" => %{"local" => %{"host" => "localhost"}}})
    end

    test "port must be an integer if present" do
      assert {:error, reason} =
               Configuration.validate_config(%{
                 "env" => %{"local" => %{"host" => "localhost", "port" => "8080"}}
               })

      assert Configuration.format_error(reason) == "port must be an integer"
    end
  end

  defp fixture(filename) do
    Path.join("test/fixtures/config", filename)
  end
end
