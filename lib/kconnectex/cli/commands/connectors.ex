defmodule Kconnectex.CLI.Commands.Connectors do
  def render(status) do
    tasks =
      Enum.flat_map(status["tasks"], fn task ->
        state = "Task #{task["id"]}: #{task["state"]}"

        if Map.has_key?(task, "trace") do
          formatted = String.split(task["trace"], "\n", trim: true)
          trace = ["Trace:", join(formatted)]

          [state | trace]
        else
          [state]
        end
      end)

    join([
      status["name"],
      String.duplicate("-", String.length(status["name"])),
      "Connector: " <> status["connector"]["state"]
      | tasks
    ])
  end

  defp join(list, sep \\ "\n") do
    binary =
      list |> Enum.intersperse(sep) |> :erlang.iolist_to_binary()

    binary <> sep
  end
end
