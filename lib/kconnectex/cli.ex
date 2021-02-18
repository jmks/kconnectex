defmodule Kconnectex.CLI do
  alias Kconnectex.CLI.Options

  def main(args) do
    opts = Options.parse(args)

    case opts.errors do
      [] ->
        run(opts)

      errors ->
        IO.puts("Here are some errors that need to be resolved:")
        Enum.each(errors, &IO.puts/1)
        IO.puts("")
        IO.puts("Run `#{:escript.script_name()} help` for usage")
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

  defp display({:ok, result}) do
    result
    |> Jason.encode!(pretty: true)
    |> IO.puts()
  end

  defp display({:error, errors}) do
    IO.puts("Error with request:")
    IO.puts(error_description(errors))
  end

  defp error_description(:econnrefused), do: "Connection to server failed"

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
