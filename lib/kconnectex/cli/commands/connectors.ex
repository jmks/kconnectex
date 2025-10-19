defmodule Kconnectex.CLI.Commands.Connectors do
  alias Kconnectex.Cli.Table

  def extract(status) do
    connector = [
      status["name"],
      "CONNECTOR",
      "",
      status["connector"]["worker_id"],
      status["connector"]["state"]
    ]

    # TODO: rows should be sorted by id
    task_rows = Enum.flat_map(status["tasks"], fn task ->
      task_row = [status["name"], "TASK", to_string(task["id"]), task["worker_id"], task["state"]]

      if Map.has_key?(task, "trace") do
        trace = String.split(task["trace"], "\n")

        [task_row | [{:lines, trace}]]
      else
        [task_row]
      end
    end)

    [connector | task_rows]
  end

  def headers do
    ["CONNECTOR", "TYPE", "ID", "WORKER_ID", "STATE"]
  end
end
