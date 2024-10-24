defmodule Kconnectex.CLI.ConfigFileTest do
  use ExUnit.Case

  alias Kconnectex.CLI.ConfigFile

  import Fixtures, only: [fixture: 1]

  describe "read/1" do
    test "reads example file" do
      assert {:ok, config} = ConfigFile.read(".kconnectex.json.example")

      assert config["selected_cluster"] == "local"
      assert config["clusters"]["local"]["host"] == "localhost"
      assert config["clusters"]["test"]["host"] == "https://testhost"
    end

    test "errors when the selected cluster is not in the list of clusters" do
      assert {:error, reason} = ConfigFile.read(fixture("config/missing_selected_cluster.json"))

      assert String.contains?(
               ConfigFile.format_error(reason),
               "selected cluster test does not exist"
             )
    end

    test "errors when configuration file is missing" do
      assert {:error, :no_configuration_file} =
               ConfigFile.read(fixture("config/nonexistant_file.json"))

      error = ConfigFile.format_error(:no_configuration_file)

      assert String.contains?(error, "Could not find configuration file")
      assert String.contains?(error, Path.join([System.user_home(), ".kconnectex.json"]))
      assert String.contains?(error, Path.join([File.cwd!(), ".kconnectex.json"]))
    end

    test "errors when configuration is not a file (e.g. :eisdir)" do
      assert {:error, :no_configuration_file} = ConfigFile.read(fixture("config/"))
    end
  end

  describe "validate_config/1" do
    setup [:valid_config, :config_without_host]

    test "errors without a host", %{invalid_config: config} do
      assert {:error, reason} = ConfigFile.validate_config(config)

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

    test "ok with valid configuration", %{valid_config: config} do
      assert {:ok, _} = ConfigFile.validate_config(config)
    end
  end

  describe "write/2" do
    @describetag :tmp_dir
    setup [:valid_config, :config_without_host]

    test "writes a valid configuration to disk", %{tmp_dir: dir, valid_config: config} do
      filepath = Path.join([dir, "serialized.json"])

      assert :ok = ConfigFile.write(config, filepath)

      assert {:ok, read_config} = ConfigFile.read(filepath)

      # when reading, we add the config_file_path key
      assert read_config[:config_file_path] == filepath
      assert Map.delete(read_config, :config_file_path) == config
    end

    test "errors when configuration is invalid", %{tmp_dir: dir, invalid_config: config} do
      filepath = Path.join([dir, "serialized.json"])

      assert {:error, reason} = ConfigFile.write(config, filepath)
      assert reason == {:missing_host, "local"}
    end

    test "does not include :config_file_path", %{tmp_dir: dir, valid_config: config} do
      filepath = Path.join([dir, "serialized.json"])

      assert :ok = ConfigFile.write(config, filepath)
      config_from_file = filepath |> File.read!() |> Jason.decode!()

      refute Map.has_key?(config_from_file, :config_file_path)
    end
  end

  def valid_config(context) do
    Map.put(context, :valid_config, %{
      "clusters" => %{"local" => %{"host" => "localhost", "port" => 8083}}
    })
  end

  def config_without_host(context) do
    Map.put(context, :invalid_config, %{"clusters" => %{"local" => %{"port" => 8083}}})
  end
end
