defmodule Kconnectex.CLI do
  def main(_), do: usage()

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
    """)
  end
end
