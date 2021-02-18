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

  defp run(%{command: ["help"]}) do
    usage()
  end

  defp run(%{command: ["cluster", "info"], url: url}) do
    url
    |> Kconnectex.client()
    |> Kconnectex.Cluster.info()
    |> display()
  end

  defp run(%{command: ["loggers"], url: url}) do
    url
    |> Kconnectex.client()
    |> Kconnectex.Admin.loggers()
    |> display()
  end

  defp run(%{command: ["loggers", logger], url: url}) do
    url
    |> Kconnectex.client()
    |> Kconnectex.Admin.logger_level(logger)
    |> display()
  end

  defp run(%{command: ["loggers", logger, level], url: url}) do
    url
    |> Kconnectex.client()
    |> Kconnectex.Admin.logger_level(logger, level)
    |> display()
  end

  defp run(%{command: ["plugins"], url: url}) do
    url
    |> Kconnectex.client()
    |> Kconnectex.ConnectorPlugins.list()
    |> display()
  end

  defp run(%{command: ["plugins", "validate"], url: url}) do
    case read_stdin() do
      {:ok, json} ->
        url
        |> Kconnectex.client()
        |> Kconnectex.ConnectorPlugins.validate_config(json)
        |> display()

      {:error, err} ->
        display_errors([Jason.DecodeError.message(err)])
    end
  end

  defp run(opts) do
    command = Enum.join(opts.command, " ")

    display_errors(["`#{command}` was not understood"])
  end

  defp display({:ok, result}) do
    result
    |> Jason.encode!(pretty: true)
    |> IO.puts()
  end

  defp display({:error, errors}) do
    IO.puts("Error with request:")
    IO.puts(error_description(errors))
  end

  defp error_description(:econnrefused), do: "  Connection to server failed"

  defp error_description(:not_found), do: "  Not found"

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

  defp usage do
    version = Application.spec(:kconnectex, :vsn)

    IO.puts("""
    Kconnectex CLI (version #{version})

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
end
