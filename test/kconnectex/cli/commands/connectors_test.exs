defmodule Kconnectex.Cli.Commands.ConnectorsTest do
  use ExUnit.Case, async: true

  alias Kconnectex.CLI.Commands.Connectors

  describe "render/1" do
    test "shows connector name" do
      status = %{
        "name" => "NAME",
        "connector" => %{"state" => "RUNNING"},
        "tasks" => []
      }

      assert Connectors.render(status) == """
             NAME
             ----
             Connector: RUNNING
             """
    end

    test "shows tasks" do
      status = %{
        "name" => "NAME",
        "connector" => %{"state" => "RUNNING"},
        "tasks" => [
          %{"id" => "0", "state" => "PAUSED"},
          %{"id" => "1", "state" => "STOPPED"},
          %{"id" => "2", "state" => "RUNNING"}
        ]
      }

      assert Connectors.render(status) == """
             NAME
             ----
             Connector: RUNNING
             Task 0: PAUSED
             Task 1: STOPPED
             Task 2: RUNNING
             """
    end

    test "shows task stack traces" do
      status = %{
        "name" => "NAME",
        "connector" => %{"state" => "RUNNING"},
        "tasks" => [
          %{"id" => "0", "state" => "PAUSED"},
          %{
            "id" => "1",
            "state" => "ERROR",
            "trace" =>
              "com.some.company.package.modules.BadException thrown by\nline 12345...\nline 123456..."
          },
          %{"id" => "2", "state" => "RUNNING"}
        ]
      }

      assert Connectors.render(status) == """
             NAME
             ----
             Connector: RUNNING
             Task 0: PAUSED
             Task 1: ERROR
             Trace:
             com.some.company.package.modules.BadException thrown by
             line 12345...
             line 123456...

             Task 2: RUNNING
             """
    end

    # defp status(name, state, tasks \\ [])
  end
end
