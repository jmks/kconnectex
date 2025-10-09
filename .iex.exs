# Convenient aliases
alias Kconnectex.{Admin, Cluster, ConnectorPlugins, Connectors, Tasks}
client = Kconnectex.client("http://0.0.0.0:8083")

defmodule Helpers.Config do
  @moduledoc """
  Some helper functions for configuring connectors
  """

  def filestream(topic \\ "license-stream", file \\ "/usr/share/doc/kafka/LICENSE") do
    %{
      "connector.class" => "FileStreamSource",
      "topic" => topic,
      "file" => file
    }
  end
end

defmodule Helpers.Connectors do
  @moduledoc """
  Some functions for working with many connectors.

  Display all their statues, pause, resume, etc.
  """

  @doc "Deletes all connectors in the client"
  def clear(client) do
    {:ok, connectors} = Kconnectex.Connectors.list(client)

    Enum.map(connectors, &Kconnectex.Connectors.delete(client, &1))
  end

  @doc "Lists connector and tasks status"
  def statuses(client) do
    {:ok, connectors} = Kconnectex.Connectors.list(client)

    Enum.each(connectors, fn conn ->
      IO.puts(String.duplicate("=", String.length(conn)))
      IO.puts(conn)
      String.duplicate("=", String.length(conn))
      {:ok, status} = Connectors.status(client, conn)
      IO.inspect(status)
    end)
  end

  @doc "Pause all RUNNING connectors and print a summary."
  def pause_running(client) do
    {:ok, connectors} = Kconnectex.Connectors.list(client)

    running = Enum.filter(connectors, fn connector ->
      {:ok, status} = Kconnectex.Connectors.status(client, connector)

      status["connector"]["state"] == "RUNNING"
    end)

    results = Enum.map(running, fn connector ->
      case Kconnectex.Connectors.pause(client, connector) do
        :ok ->
          IO.puts("#{connector} paused.")
          true

        {:error, reason} ->
          IO.puts("Error pausing #{connector}: #{reason}")
          false
      end
    end)

    if Enum.all?(results) do
      IO.puts("Success!")
    else
      IO.puts("There may have been partial errors. See output for details.")
    end
  end

  @doc "Resume all PAUSED connectors and print a summary."
  def resume_paused(client) do
    {:ok, connectors} = Kconnectex.Connectors.list(client)

    paused = Enum.filter(connectors, fn connector ->
      {:ok, status} = Kconnectex.Connectors.status(client, connector)

      status["connector"]["state"] == "PAUSED"
    end)

    results = Enum.map(paused, fn connector ->
      case Kconnectex.Connectors.resume(client, connector) do
        :ok ->
          IO.puts("#{connector} resumed.")
          true

        {:error, reason} ->
          IO.puts("Error resuming #{connector}: #{reason}")
          false
      end
    end)

    if Enum.all?(results) do
      IO.puts("Success!")
    else
      IO.puts("There may have been partial errors. See output for details.")
    end
  end
end
