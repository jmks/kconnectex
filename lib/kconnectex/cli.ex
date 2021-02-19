defmodule Kconnectex.CLI do
  alias Kconnectex.CLI.Options

  def main(args) do
    opts = Options.parse(args)

    case opts.errors do
      [] ->
        run(opts)

      errors ->
        display_errors(errors)
    end
  end

  defp run(%{command: ["help"]}), do: help(:usage)

  defp run(%{command: ["cluster", "help"]}), do: help(:cluster)

  defp run(%{command: ["cluster", "info"], url: url}) do
    client(url)
    |> Kconnectex.Cluster.info()
    |> display()
  end

  defp run(%{command: ["loggers", "help"]}), do: help(:loggers)

  defp run(%{command: ["loggers"], url: url}) do
    client(url)
    |> Kconnectex.Admin.loggers()
    |> display()
  end

  defp run(%{command: ["loggers", logger], url: url}) do
    client(url)
    |> Kconnectex.Admin.logger_level(logger)
    |> display()
  end

  defp run(%{command: ["loggers", logger, level], url: url}) do
    client(url)
    |> Kconnectex.Admin.logger_level(logger, level)
    |> display()
  end

  defp run(%{command: ["plugins", "help"]}), do: help(:plugins)

  defp run(%{command: ["plugins"], url: url}) do
    client(url)
    |> Kconnectex.ConnectorPlugins.list()
    |> display()
  end

  defp run(%{command: ["plugins", "validate"], url: url}) do
    case read_stdin() do
      {:ok, json} ->
        client(url)
        |> Kconnectex.ConnectorPlugins.validate_config(json)
        |> display()

      {:error, err} ->
        display_errors([Jason.DecodeError.message(err)])
    end
  end

  defp run(%{command: ["tasks", "help"]}), do: help(:tasks)

  defp run(%{command: ["tasks", connector], url: url}) do
    client(url)
    |> Kconnectex.Tasks.list(connector)
    |> display()
  end

  defp run(%{command: ["tasks", "status", connector, task_id], url: url}) do
    client(url)
    |> Kconnectex.Tasks.status(connector, task_id)
    |> display()
  end

  defp run(%{command: ["tasks", "restart", connector, task_id], url: url}) do
    client(url)
    |> Kconnectex.Tasks.restart(connector, task_id)
    |> display()
  end

  defp run(%{command: ["connectors", "help"]}), do: help(:connectors)

  defp run(%{command: ["connectors"], url: url}) do
    client(url)
    |> Kconnectex.Connectors.list()
    |> display()
  end

  defp run(%{command: ["connectors", "create", connector], url: url}) do
    case read_stdin() do
      {:ok, json} ->
        client(url)
        |> Kconnectex.Connectors.create(connector, json)
        |> display()

      {:error, err} ->
        display_errors([Jason.DecodeError.message(err)])
    end
  end

  defp run(%{command: ["connectors", "update", connector], url: url}) do
    case read_stdin() do
      {:ok, json} ->
        client(url)
        |> Kconnectex.Connectors.update(connector, json)
        |> display()

      {:error, err} ->
        display_errors([Jason.DecodeError.message(err)])
    end
  end

  defp run(%{command: ["connectors", subcommand, connector], url: url})
       when subcommand in ~w(config delete info pause restart resume status) do
    sub = String.to_atom(subcommand)

    apply(Kconnectex.Connectors, sub, [client(url), connector])
    |> display()
  end

  defp run(opts) do
    command = Enum.join(opts.command, " ")

    display_errors(["`#{command}` was not understood"])
  end

  defp client(url), do: Kconnectex.client(url)

  defp display(:ok), do: IO.puts("Success")

  defp display({:ok, result}) do
    result
    |> Jason.encode!(pretty: true)
    |> IO.puts()
  end

  defp display({:error, %{"message" => message}}) do
    IO.puts("Error with request:")
    IO.puts(error_description([message]))
  end

  defp display({:error, errors}) do
    IO.puts("Error with request:")
    IO.puts(error_description(errors))
  end

  defp error_description(:econnrefused), do: "  Connection to server failed"

  defp error_description(:not_found), do: "  Not found"

  defp error_description(:rebalancing), do: "  Connect is rebalancing. Try again later."

  defp error_description(errors) when is_list(errors) do
    errors
    |> Enum.map(&"  #{&1}")
    |> Enum.join("\n")
  end

  defp display_errors(errors) do
    IO.puts("Here are some errors that need to be resolved:")
    Enum.each(errors, &IO.puts/1)
    IO.puts("")
    IO.puts("Run `#{:escript.script_name()} help` for usage")
  end

  defp read_stdin do
    IO.read(:stdio, :all)
    |> String.trim()
    |> Jason.decode()
  end

  defp help(:usage) do
    IO.puts("""
    #{help_header()}

    Global options:
      --url
        URL to Kafka Connect Cluster

    Commands:
      cluster
      loggers
      plugins
      connectors
      tasks

      help (this!)
    """)
  end

  defp help(:cluster) do
    IO.puts("""
    #{help_header()}

    cluster info
      Display information about Kafka Connect cluster
    """)
  end

  defp help(:loggers) do
    IO.puts("""
    #{help_header()}

    loggers
      List logger levels on the Connect worker

    loggers LOGGER
      Get the logger level of the given LOGGER

    loggers LOGGER LEVEL
      Set the logger level to LEVEL of the given LOGGER
    """)
  end

  defp help(:plugins) do
    IO.puts("""
    #{help_header()}

    plugins
      List plugins installed on Connect worker

    plugins validate
      Validate connector plugin configuration.
      Configuration is read from STDIN and assumed to be JSON.
    """)
  end

  defp help(:tasks) do
    IO.puts("""
    #{help_header()}

    tasks CONNECTOR
      List tasks for a given CONNECTOR.

    tasks status CONNECTOR TASK_ID
      Get status of the TASK_ID for a given CONNECTOR.

    tasks restart CONNECTOR TASK_ID
      Restart TASK_ID for a given CONNECTOR.
    """)
  end

  defp help(:connectors) do
    IO.puts("""
    #{help_header()}

    connectors
      Lists connectors.

    connectors config CONNECTOR
      Get configuration for the given CONNECTOR.

    connectors create CONNECTOR
      Create a connector with name CONNECTOR.
      Configuration is read from STDIN and assumed to be JSON.

    connectors delete CONNECTOR
      Delete the given CONNECTOR.

    connectors info CONNECTOR
      Get configuration and tasks for the given CONNECTOR.

    connectors pause CONNECTOR
      Pause the given CONNECTOR.

    connectors restart CONNECTOR
      Restart the given CONNECTOR.

    connectors resume CONNECTOR
      Resume the given CONNECTOR.

    connectors status CONNECTOR
      Get status of the given CONNECTOR.

    connectors update CONNECTOR
      Update configuration for the given CONNECTOR.
      Configuration is read from STDIN and assumed to be JSON.
    """)
  end

  defp help_header do
    version = Application.spec(:kconnectex, :vsn)

    "Kafka Connect CLI (version #{version})"
  end
end
