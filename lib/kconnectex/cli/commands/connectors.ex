defmodule Kconnectex.CLI.Commands.Connectors do
  alias TableRex.Table

  def extract(status) do
    connector = [
      status["name"],
      "CONNECTOR",
      nil,
      status["connector"]["worker_id"],
      status["connector"]["state"]
    ]

    tasks =
      for task <- status["tasks"] do
        [status["name"], "TASK", task["id"], task["worker_id"], task["state"]]
      end

    [connector | tasks]
  end

  def render(status_rows) do
    # TODO: how to show the trace?
    Table.new(status_rows, headers())
    |> Table.render!(
      horizontal_style: :off,
      vertical_style: :off,
      top_frame_symbol: false
    )
  end

  defp headers do
    ["CONNECTOR", "TYPE", "ID", "WORKER_ID", "STATE"]
  end
end
