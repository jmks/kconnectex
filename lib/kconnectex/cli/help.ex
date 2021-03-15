defmodule Kconnectex.CLI.Help do
  @spec help(:cluster | :config | :connectors | :loggers | :plugins | :tasks | :usage) :: :ok
  def help(:usage) do
    IO.puts("""
    #{help_header()}

    Global options:
      --url
        URL to Kafka Connect Cluster
      --help
        Display usage or help for commands

    Commands:
      cluster
      config
      connectors
      connector
      loggers
      logger
      plugins
      tasks
      task
    """)
  end

  def help(:cluster) do
    IO.puts("""
    #{help_header()}

    cluster
      Display information about Kafka Connect cluster
    """)
  end

  def help(:config) do
    IO.puts("""
    #{help_header()}

    config
      Display current configuration

    config add NAME HOST PORT
      Add a new environment to the configuration file.
      NAME is the environment name.
      PORT is optional; default: 8083

    config remove NAME
      Remove NAME environment from configuration file.

    config select NAME
      Select NAME as the default environment.
    """)
  end

  def help(:loggers) do
    IO.puts("""
    #{help_header()}

    loggers
      List logger levels on the Connect worker

    logger LOGGER
      Get the logger level of the given LOGGER

    logger LOGGER LEVEL
      Set the logger level to LEVEL for the given LOGGER
    """)
  end

  def help(:plugins) do
    IO.puts("""
    #{help_header()}

    plugins
      List plugins installed on Connect worker

    plugins validate
      Validate connector plugin configuration.
      Configuration is read from STDIN and assumed to be JSON.
    """)
  end

  def help(:tasks) do
    IO.puts("""
    #{help_header()}

    tasks CONNECTOR
      List tasks for a given CONNECTOR.

    task status CONNECTOR TASK_ID
      Get status of the TASK_ID for a given CONNECTOR.

    task restart CONNECTOR TASK_ID
      Restart TASK_ID for a given CONNECTOR.
    """)
  end

  def help(:connectors) do
    IO.puts("""
    #{help_header()}

    connectors
      Lists connectors.

    connector config CONNECTOR
      Get configuration for the given CONNECTOR.

    connector create CONNECTOR
      Create a connector with name CONNECTOR.
      Configuration is read from STDIN and assumed to be JSON.

    connector delete CONNECTOR
      Delete the given CONNECTOR.

    connector info CONNECTOR
      Get configuration and tasks for the given CONNECTOR.

    connector pause CONNECTOR
      Pause the given CONNECTOR.

    connector restart CONNECTOR
      Restart the given CONNECTOR.

    connector resume CONNECTOR
      Resume the given CONNECTOR.

    connector status CONNECTOR
      Get status of the given CONNECTOR.

    connector update CONNECTOR
      Update configuration for the given CONNECTOR.
      Configuration is read from STDIN and assumed to be JSON.
    """)
  end

  defp help_header do
    version = Application.spec(:kconnectex, :vsn)

    "Kafka Connect CLI (version #{version})"
  end
end
