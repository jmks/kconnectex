defmodule Kconnectex.Admin do
  alias Kconnectex.Request

  # https://docs.confluent.io/platform/current/connect/logging.html#kconnect-long-logging
  @logger_levels ~w(OFF FATAL ERROR WARN INFO DEBUG TRACE)

  def loggers(client) do
    Request.new(client)
    |> Request.get("/admin/loggers")
    |> Request.execute()
  end

  def logger_level(client, logger) do
    Request.new(client)
    |> Request.validate({:present, logger}, "logger must be present")
    |> Request.get("/admin/loggers/#{logger}")
    |> Request.execute()
  end

  def logger_level(client, logger, level) do
    Request.new(client)
    |> Request.validate({:present, logger}, "logger must be present")
    |> Request.validate(
      {:in, level, @logger_levels},
      "level must be one of: #{Enum.join(@logger_levels, ", ")}"
    )
    |> Request.put("/admin/loggers/#{logger}", %{"level" => level})
    |> Request.execute()
  end
end
