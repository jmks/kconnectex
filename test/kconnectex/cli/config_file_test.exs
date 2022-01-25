defmodule Kconnectex.CLI.ConfigFileTest do
  use ExUnit.Case

  alias Kconnectex.CLI.ConfigFile

  test "example is valid" do
    assert {:ok, _} = ConfigFile.load(".kconnectex.json.example")
  end

  test "returns an error when the selected cluster is not in the list of clusters" do
    assert {:error, reason} = ConfigFile.load(fixture("missing_selected_cluster.json"))

    assert String.contains?(
             ConfigFile.format_error(reason),
             "selected cluster test does not exist"
           )
  end

  test "returns an error when configuration file is missing" do
    assert {:error, :no_configuration_file} = ConfigFile.load(fixture("nonexistant_file.json"))
  end

  test "returns an error when configuration is not a file (:eisdir)" do
    assert {:error, :no_configuration_file} = ConfigFile.load(fixture(""))
  end

  describe ".validate_config" do
    test "errors without a host" do
      assert {:error, reason} =
               ConfigFile.validate_config(%{"clusters" => %{"local" => %{"port" => 8083}}})

      assert ConfigFile.format_error(reason) == "cluster local must specify a host"
    end

    test "errors when host is not a string" do
      assert {:error, reason} =
               ConfigFile.validate_config(%{"clusters" => %{"local" => %{"host" => 8083}}})

      assert ConfigFile.format_error(reason) == "cluster local host must be a string"
    end

    test "errors when port provided but not an integer" do
      assert {:error, reason} =
               ConfigFile.validate_config(%{
                 "clusters" => %{"local" => %{"host" => "localhost", "port" => "8080"}}
               })

      assert ConfigFile.format_error(reason) == "cluster local port must be an integer"
    end

    setup :valid_config
    test "ok with valid configuration", %{valid_config: config} do
      assert {:ok, _} = ConfigFile.validate_config(config)
    end
  end

  @tag :tmp_dir
  describe ".write" do
    setup :valid_config
    test "writes a valid configuration to disk", %{tmp_dir: dir, valid_config: config} do
      filepath = Path.join([dir, "serialized.json"])

      assert :ok = ConfigFile.write(config, filepath)

      assert {:ok, read_config} = ConfigFile.load(filepath)

      # when reading, we add the config_file_path key
      assert read_config[:config_file_path] == filepath
      assert Map.delete(read_config, :config_file_path) == config
    end
  end

  defp fixture(filename) do
    Path.join("test/fixtures/config", filename)
  end

  def valid_config(context) do
    Map.put(context, :valid_config, %{
      "clusters" => %{"local" => %{"host" => "localhost", "port" => 8083}}
    })
  end
end
