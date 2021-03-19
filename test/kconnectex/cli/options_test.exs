defmodule Kconnectex.CLI.OptionsTest do
  use ExUnit.Case, async: true

  alias Kconnectex.CLI.Options

  test "usage" do
    opts = Options.parse(["--help"])

    assert opts.help?
  end

  test "--url or --cluster required" do
    opts = Options.parse(["connectors"])

    assert "--url is required" in opts.errors
  end

  test "--cluster" do
    opts = Options.parse(["--cluster", "apple"])

    assert opts.cluster == "apple"
  end

  test "--url prefered over --cluster" do
    opts = Options.parse(["--cluster", "apple", "--url", "example.com"])

    assert opts.url == "example.com"
    assert opts.cluster == :no_configuration
  end

  test "unexpected options are errors" do
    opts = Options.parse(["--unexpected"])

    assert "--unexpected is not valid" in opts.errors
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

  describe "update" do
    test "use selected cluster if configured" do
      opts = %Options{url: nil, errors: ["--url is required"]}

      config = %{
        "global" => %{"selected_env" => "local"},
        "env" => %{
          "local" => %{"host" => "localhost", "port" => 9999}
        }
      }

      assert %{url: "localhost:9999", errors: []} = Options.update(opts, {:ok, config})
    end

    test "use --cluster if configured" do
      opts = %Options{cluster: "test"}

      config = %{
        "env" => %{
          "test" => %{"host" => "testhost", "port" => 9999}
        }
      }

      assert %{url: "testhost:9999"} = Options.update(opts, {:ok, config})
    end

    test "uses 8083 as default port if port not configured" do
      opts = %Options{url: nil, errors: ["--url is required"]}

      config = %{
        "global" => %{"selected_env" => "local"},
        "env" => %{
          "local" => %{"host" => "localhost"}
        }
      }

      assert %{url: "localhost:8083", errors: []} = Options.update(opts, {:ok, config})
    end

    test "keep --url option if not configured" do
      opts = %Options{url: "remote-host:8080"}
      config = %{"env" => %{"local" => %{"host" => "localhost"}}}

      assert %{url: "remote-host:8080"} = Options.update(opts, {:ok, config})
    end

    test "adds error when --cluster does not exist" do
      opts = %Options{url: "remote:8080", cluster: "local"}
      config = %{}

      assert %{errors: ["Cluster local was not found in the configuration"]} =
               Options.update(opts, {:ok, config})
    end

    test "adds error when selected cluster does not exist" do
      opts = %Options{}

      config = %{
        "global" => %{"selected_env" => "local"},
        "env" => %{}
      }

      assert %{errors: ["Selected cluster local was not found in the configuration"]} =
               Options.update(opts, {:ok, config})
    end
  end
end
