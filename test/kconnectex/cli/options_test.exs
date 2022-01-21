defmodule Kconnectex.CLI.OptionsTest do
  use ExUnit.Case, async: true

  alias Kconnectex.CLI.Options

  describe "parse" do
    test "help flag" do
      opts = Options.parse(["--help"])

      assert opts.help?
    end

    test "unexpected options are errors" do
      opts = Options.parse(["--unexpected"])

      assert "--unexpected is not valid" in opts.errors
    end

    test "--url is required with no configuration file" do
      opts = Options.parse(["connectors"])

      assert "Either create a configuration file or explictly use the --url option" in opts.errors
    end

    test "no url is required when working with configuration" do
      opts = Options.parse(["config"])

      assert opts.errors == []
    end

    test "no command defaults to help" do
      opts = Options.parse([])

      assert opts.help?
    end

    test "a valid command" do
      opts = Options.parse(["--url", "example.com", "cluster", "info"])

      assert opts.url == "example.com"
      assert opts.command == ["cluster", "info"]
      assert opts.errors == []
    end

    test "use cluster from configuration" do
      config = %{
        "selected_cluster" => "local",
        "clusters" => %{
          "local" => %{"host" => "localhost", "port" => 9999}
        }
      }

      assert %{url: "localhost:9999", errors: []} = Options.parse(["cluster"], config)
    end

    test "use cluster from configuration with no port" do
      config = %{
        "selected_cluster" => "local",
        "clusters" => %{
          "local" => %{"host" => "localhost"}
        }
      }

      assert %{url: "localhost", errors: []} = Options.parse(["cluster"], config)
    end

    test "adds error when selected cluster does not exist" do
      config = %{
        "selected_cluster" => "local",
        "clusters" => %{}
      }

      options = Options.parse(["cluster"], config)

      assert options.errors == ["selected cluster local was not found in the configuration"]
    end

    test "use --cluster option" do
      config = %{
        "clusters" => %{
          "test" => %{"host" => "testhost", "port" => 9999}
        }
      }

      assert %{url: "testhost:9999"} = Options.parse(["--cluster", "test", "cluster"], config)
    end

    test "adds error when --cluster does not exist" do
      assert %{errors: ["Cluster unknown was not found in the configuration"]} =
               Options.parse(["--cluster", "unknown", "cluster"], %{})
    end

    test "--url is preferred over --cluster, which is preferred over configuration" do
      config = %{
        "selected_cluster" => "local",
        "clusters" => %{
          "local" => %{"host" => "localhost"},
          "override" => %{"host" => "localoverride"}
        }
      }

      assert %{url: "localhost"} = Options.parse(["cluster"], config)

      assert %{url: "localoverride", errors: []} =
               Options.parse(["--cluster", "override", "cluster"], config)

      assert %{url: "example.com"} =
               Options.parse(["--url", "example.com", "--cluster", "override", "cluster"], config)
    end
  end
end
