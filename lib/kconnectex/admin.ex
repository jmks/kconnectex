defmodule Kconnectex.Admin do
  @moduledoc """
  Endpoints to check or change log levels.

  https://docs.confluent.io/platform/current/connect/references/restapi.html#log-levels
  https://docs.confluent.io/platform/current/connect/logging.html#connect-logging-using-api
  """

  alias Kconnectex.Request

  # https://docs.confluent.io/platform/current/connect/logging.html#kconnect-long-logging
  @logger_levels ~w(OFF FATAL ERROR WARN INFO DEBUG TRACE)

  @doc """
  Display logging levels for specific loggers.

  ## Parameters

    - client: client from `Kconnectex.client/1`

  ## Examples

      > Kconnectex.Cluster.info(client)

      {:ok,
       %{"org.reflections" => %{"level" => "ERROR"}, "root" => %{"level" => "INFO"}}
  """
  def loggers(client) do
    Request.new(client)
    |> Request.get("/admin/loggers")
    |> Request.execute()
  end

  @doc """
  Display logging level for specific logger.

  ## Parameters

  - client: client from `Kconnectex.client/1`
  - logger: name of logger

  ## Examples

      > Admin.logger_level(client, "io.debezium.connector.postgresql.PostgresConnector")

      {:ok, %{"level" => "DEBUG"}}
  """
  def logger_level(client, logger) do
    Request.new(client)
    |> Request.validate({:present, logger}, "logger must be present")
    |> Request.get("/admin/loggers/#{logger}")
    |> Request.execute()
  end

  @doc """
  Updates logging level for a logger.

  ## Parameters

  - client: client from `Kconnectex.client/1`
  - logger: name of logger
  - level: level to set logger to. Must be one of `@logger_levels`

  ## Examples

      > Admin.logger_level(client, "io.debezium", "TRACE")

      {:ok,
       ["io.debezium", "io.debezium.connector.mongodb.MongoDbConnector",
       "io.debezium.connector.mysql.MySqlConnector",
       "io.debezium.connector.postgresql.PostgresConnector",
       "io.debezium.util.IoUtil"]}

      > Admin.logger_level(client, "io.debezium.connector.postgresql.PostgresConnector")

      {:ok, %{"level" => "TRACE"}}
  """
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
