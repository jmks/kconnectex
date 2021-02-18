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

  defp usage do
    version = Application.spec(:kconnectex, :vsn)

    IO.puts("""
    Kconnectex CLI (version #{version})

    Global options:
      --url
        URL to Kafka Connect Cluster

    Commands:
      admin
      cluster
      plugins
      connectors
      tasks

      help (this!)
    """)
  end
end
