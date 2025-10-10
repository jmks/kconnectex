defmodule Kconnectex.Cli.Commands.ConnectorsTest do
  use ExUnit.Case, async: true

  alias Kconnectex.CLI.Commands.Connectors

  describe "render/1" do
    test "shows connector name" do
      status = connector("NAME", "RUNNING")

      assert render(status) == """
              CONNECTOR   TYPE        ID   WORKER_ID   STATE

              NAME        CONNECTOR        localhost   RUNNING
             """
    end

    test "shows tasks" do
      status =
        connector("NAME", "RUNNING",
          tasks: [
            task(0, "PAUSED"),
            task(1, "STOPPED"),
            task(2, "RUNNING")
          ]
        )

      assert render(status) == """
              CONNECTOR   TYPE        ID   WORKER_ID   STATE

              NAME        CONNECTOR        localhost   RUNNING
              NAME        TASK        0    localhost   PAUSED
              NAME        TASK        1    localhost   STOPPED
              NAME        TASK        2    localhost   RUNNING
             """
    end

    test "shows task stack traces" do
      status =
        connector("NAME", "RUNNING",
          tasks: [
            task(0, "PAUSED"),
            task(1, "ERROR",
              trace:
                "com.some.company.package.modules.BadException thrown by\nline 12345...\nline 123456..."
            ),
            task(2, "RUNNING")
          ]
        )

      assert render(status) == """
              CONNECTOR   TYPE        ID   WORKER_ID   STATE

              NAME        CONNECTOR        localhost   RUNNING
              NAME        TASK        0    localhost   PAUSED
              NAME        TASK        1    localhost   ERROR
              NAME        TASK        2    localhost   RUNNING
             """
    end

    defp render(status) do
      status
      |> Connectors.extract()
      |> Connectors.render()
    end

    defp connector(name, state, opts \\ []) do
      %{
        "name" => name,
        "connector" => %{
          "state" => state,
          "worker_id" => Keyword.get(opts, :worker_id, "localhost")
        },
        "tasks" => Keyword.get(opts, :tasks, []),
        "type" => Keyword.get(opts, :type, "source")
      }
    end

    defp task(id, state, opts \\ []) do
      t = %{
        "id" => id,
        "state" => state,
        "worker_id" => Keyword.get(opts, :worker_id, "localhost")
      }

      if Keyword.has_key?(opts, :trace) do
        Map.put(t, :trace, Keyword.fetch!(opts, :trace))
      end

      t
    end
  end
end
