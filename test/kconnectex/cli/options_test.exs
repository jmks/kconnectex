defmodule Kconnectex.CLI.OptionsTest do
  use ExUnit.Case, async: true

  alias Kconnectex.CLI.Options

  describe ".parse/1" do
    test "--help" do
      assert Options.parse(["--help"]).help?
    end

    test "--help by default" do
      assert Options.parse([]).help?
    end

    test "unexpected options are errors" do
      opts = Options.parse(["--unexpected"])

      assert "Unknown flag: --unexpected" in opts.errors
    end

    test "--url is required" do
      opts = Options.parse(["connectors"])

      assert "Either create a configuration file or explictly provide --url" in opts.errors
    end

    test "--url not required with --help" do
      opts = Options.parse(["--help"])

      assert opts.errors == []
    end

    test "--url not required when working with configuration" do
      opts = Options.parse(["config"])

      assert opts.errors == []
    end

    test "--cluster is an error" do
      options = Options.parse(["--cluster", "unknown", "cluster"])

      assert "--cluster was provided but no configuration file was found" in options.errors
    end

    test "a valid command" do
      opts = Options.parse(["--url", "example.com", "cluster", "info"])

      assert opts.url == "example.com"
      assert opts.command == ["cluster", "info"]
      assert opts.errors == []
    end
  end

  describe "connectors" do
    test "connectors --expand info" do
      opts = Options.parse(["--url", "example.com", "connectors", "--expand", "info"])

      assert Enum.empty?(opts.errors)
      assert {:expand, :info} in opts.options
    end

    test "connectors --expand status" do
      opts = Options.parse(["--url", "example.com", "connectors", "--expand", "status"])

      assert Enum.empty?(opts.errors)
      assert {:expand, :status} in opts.options
    end

    test "connectors --expand info,status does both" do
      opts = Options.parse(["--url", "example.com", "connectors", "--expand", "info,status"])

      assert Enum.empty?(opts.errors)
      assert {:expand, [:info, :status]} in opts.options
    end

    test "errors with unknown expansion" do
      opts = Options.parse(["--url", "example.com", "connectors", "--expand", "bigbang"])

      assert "Unknown value for --expand: bigbang" in opts.errors
    end
  end

  describe "connector restart" do
    test "connector restart :name" do
      opts = Options.parse(["--url", "example.com", "connector", "restart", "debezium"])

      assert Enum.empty?(opts.errors)
      assert opts.command == ["connector", "restart", "debezium"]
    end

    test "connector restart :name --only-failed" do
      opts =
        Options.parse([
          "--url",
          "example.com",
          "connector",
          "restart",
          "debezium",
          "--only-failed"
        ])

      assert Enum.empty?(opts.errors)
      assert opts.command == ["connector", "restart", "debezium"]
      assert {:only_failed, true} in opts.options
    end

    test "connector restart :name --include-tasks" do
      opts =
        Options.parse([
          "--url",
          "example.com",
          "connector",
          "restart",
          "debezium",
          "--include-tasks"
        ])

      assert Enum.empty?(opts.errors)
      assert opts.command == ["connector", "restart", "debezium"]
      assert {:include_tasks, true} in opts.options
    end

    test "connector restart :name --only-failed --include-tasks" do
      opts =
        Options.parse([
          "--url",
          "example.com",
          "connector",
          "restart",
          "debezium",
          "--include-tasks",
          "--only-failed"
        ])

      assert Enum.empty?(opts.errors)
      assert opts.command == ["connector", "restart", "debezium"]
      assert {:include_tasks, true} in opts.options
      assert {:only_failed, true} in opts.options
    end
  end

  describe ".parse/2" do
    test "--cluster from configuration" do
      config = %{
        "clusters" => %{
          "test" => %{"host" => "testhost", "port" => 9999}
        }
      }

      opts = Options.parse(["--cluster", "test", "cluster"], config)

      assert opts.errors == []
      assert opts.url == "testhost:9999"
    end

    test "--cluster is error when not present" do
      config = %{
        "clusters" => %{
          "other" => %{"host" => "testhost"}
        },
        config_file_path: "some_path.json"
      }

      options = Options.parse(["--cluster", "some_other", "cluster"], config)

      assert "The provided --cluster 'some_other' was not found in the configuration file 'some_path.json'" in options.errors
    end

    test "implicit selected cluster" do
      config = %{
        "selected_cluster" => "local",
        "clusters" => %{
          "local" => %{"host" => "localhost", "port" => 9999}
        }
      }

      opts = Options.parse(["cluster"], config)

      assert opts.errors == []
      assert opts.url == "localhost:9999"
    end

    test "implicit selected cluster without a port" do
      config = %{
        "selected_cluster" => "local",
        "clusters" => %{
          "local" => %{"host" => "localhost"}
        }
      }

      opts = Options.parse(["cluster"], config)

      assert opts.errors == []
      assert opts.url == "localhost"
    end

    test "implicit selected cluster is an error when cluster is not present" do
      config = %{
        "selected_cluster" => "local",
        "clusters" => %{}
      }

      options = Options.parse(["cluster"], config)

      assert options.errors == ["selected cluster local was not found in the configuration"]
    end

    test "--url preferred to --cluster perferred to configuration" do
      config = %{
        "selected_cluster" => "local",
        "clusters" => %{
          "local" => %{"host" => "selected"},
          "override" => %{"host" => "cluster-option"}
        }
      }

      assert %{url: "selected"} = Options.parse(["cluster"], config)

      assert %{url: "cluster-option", errors: []} =
               Options.parse(["--cluster", "override", "cluster"], config)

      assert %{url: "url-option"} =
               Options.parse(["--url", "url-option", "--cluster", "override", "cluster"], config)
    end
  end
end
