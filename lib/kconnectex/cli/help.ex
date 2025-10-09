defmodule Kconnectex.CLI.Help do
  @spec help(:cluster | :config | :connectors | :loggers | :plugins | :tasks | :usage) :: :ok
  def help(:usage) do
    IO.puts("""
    #{help_header()}

    Global options:
      --url
        URL to Kafka Connect Cluster
      --cluster NAME
        Use NAME configured cluster
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
      plugin
      tasks
      task
    """)
  end

  def help(:cluster) do
    IO.puts("""
    #{help_header()}

    info
      Display information about Kafka Connect cluster

    health
      Display the health of the Kafka Connect cluster
    """)
  end

  def help(:config) do
    IO.puts("""
    #{help_header()}

    config
      Display current configuration

    config add NAME HOST PORT
      Add (or update) a cluster to the configuration file.
      NAME is the cluster name.
      PORT is optional.

    config remove NAME
      Remove configuration for cluster NAME.

    config select NAME
      Select NAME as the default cluster.
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

    plugin validate [--errors-only]
      Validate connector plugin configuration.
      ConfigFile is read from STDIN and assumed to be JSON.

      --errors-only
      Filters the configuration to only those with errors.
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
      ConfigFile is read from STDIN and assumed to be JSON.

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
      ConfigFile is read from STDIN and assumed to be JSON.
    """)
  end

  defp help_header do
    version = Application.spec(:kconnectex, :vsn)

    "Kafka Connect CLI (version #{version})"
  end
end
