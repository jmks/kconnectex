defmodule Kconnectex.CLI.Commands.Loggers do
  def extract(loggers) do
    Enum.map(loggers, fn {name, logger} ->
      [
        name,
        logger["level"],
        last_modified(logger["last_modified"])
      ]
    end)
    |> Enum.sort()
  end

  def headers do
    ["LOGGER", "LEVEL", "LAST MODIFIED"]
  end

  defp last_modified(nil), do: ""

  defp last_modified(timestamp) do
    case DateTime.from_unix(timestamp, :millisecond) do
      {:ok, datetime} ->
        Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S")

      otherwise ->
        to_string(otherwise)
    end
  end
end
