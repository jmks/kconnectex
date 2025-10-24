defmodule Kconnectex.CLI.Commands.Connectors do
  def extract(status) do
    connector = [
      status["name"],
      "CONNECTOR",
      "",
      status["connector"]["worker_id"],
      status["connector"]["state"]
    ]

    task_rows =
      status["tasks"]
      |> Enum.sort_by(fn task -> task["id"] end)
      |> Enum.flat_map(fn task ->
        task_row = [
          status["name"],
          "TASK",
          to_string(task["id"]),
          task["worker_id"],
          task["state"]
        ]

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
    [
      "CONNECTOR",
      %{name: "TYPE", min_width: String.length("CONNECTOR")},
      "ID",
      "WORKER_ID",
      %{name: "STATE", min_width: String.length("RUNNING")}
    ]
  end
end
