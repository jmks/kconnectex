defmodule Kconnectex.Admin do
  import Kconnectex.Util

  # https://docs.confluent.io/platform/current/connect/logging.html#kconnect-long-logging
  @logger_levels ~w(OFF FATAL ERROR WARN INFO DEBUG TRACE)

  def loggers(client) do
    handle_response(Tesla.get(client, "/admin/loggers"))
  end

  def logger_level(client, logger) do
    handle_response(Tesla.get(client, "/admin/loggers/#{logger}"))
  end

  def logger_level(client, logger, level) when level in @logger_levels do
    handle_response(Tesla.put(client, "/admin/loggers/#{logger}", %{"level" => level}))
  end
end
