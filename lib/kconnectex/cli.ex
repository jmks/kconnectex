defmodule Kconnectex.CLI do
  alias Kconnectex.CLI.{Configuration, Options}

  import Kconnectex.CLI.Help

  def main(args) do
    opts = Options.extract(args)

    case opts do
      {:error, reason} ->
        display_errors([reason])

      %{errors: []} ->
        run(opts)

      %{errors: errors} ->
        display_errors(errors)
    end
  end

  defp run(%{help?: true, command: context} = opts) do
    case context do
      ["cluster" | _] -> help(:cluster)
      ["loggers" | _] -> help(:loggers)
      ["logger" | _] -> help(:loggers)
      ["plugins" | _] -> help(:plugins)
      ["tasks" | _] -> help(:tasks)
      ["task" | _] -> help(:tasks)
      ["connectors" | _] -> help(:connectors)
      ["connector" | _] -> help(:connectors)
      ["config" | _] -> help(:config)
      [] -> help(:usage)
      _ -> unknown_command(opts)
    end
  end

  defp run(%{command: ["config"]} = opts) do
    display_config(opts.config)
  end

  defp run(%{command: ["config", "add", name, host, port]} = opts) do
    add_cluster(opts.config, name, host, port)
  end

  defp run(%{command: ["config", "add", name, host]} = opts) do
    add_cluster(opts.config, name, host)
  end

  defp run(%{command: ["config", "select", selected]} = opts) do
    case opts.config do
      :no_configuration_file ->
        IO.puts("No configuration file found.")

      config ->
        if get_in(config, ["clusters", selected]) do
          config
          |> Map.put("selected_cluster", selected)
          |> Configuration.write()
          |> display()
        else
          cluster_choices =
            config["clusters"]
            |> Map.keys()
            |> Enum.join(", ")

          IO.puts("Cluster #{selected} not found in configuration")
          IO.puts("Found clusters: #{cluster_choices}")
        end
    end
  end

  defp run(%{command: ["config", "remove", name]} = opts) do
    case opts.config do
      :no_configuration_file ->
        display(:ok)

      config ->
        if get_in(config, ["clusters", name]) do
          new_config = pop_in(config, ["clusters", name]) |> elem(1)

          new_config =
            if new_config["selected_cluster"] do
              Map.delete(new_config, "selected_cluster")
            else
              new_config
            end

          new_config
          |> Configuration.write()
          |> display()
        else
          display(:ok)
        end
    end
  end

  defp run(%{command: ["cluster"], url: url}) do
    client(url)
    |> Kconnectex.Cluster.info()
    |> display()
  end

  defp run(%{command: ["loggers"], url: url}) do
    client(url)
    |> Kconnectex.Admin.loggers()
    |> display()
  end

  defp run(%{command: ["logger", logger], url: url}) do
    client(url)
    |> Kconnectex.Admin.logger_level(logger)
    |> display()
  end

  defp run(%{command: ["logger", logger, level], url: url}) do
    client(url)
    |> Kconnectex.Admin.logger_level(logger, level)
    |> display()
  end

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

  defp run(%{command: ["tasks", connector], url: url}) do
    client(url)
    |> Kconnectex.Tasks.list(connector)
    |> display()
  end

  defp run(%{command: ["task", "status", connector, task_id], url: url}) do
    client(url)
    |> Kconnectex.Tasks.status(connector, task_id)
    |> display()
  end

  defp run(%{command: ["task", "restart", connector, task_id], url: url}) do
    client(url)
    |> Kconnectex.Tasks.restart(connector, task_id)
    |> display()
  end

  defp run(%{command: ["connectors"], url: url}) do
    client(url)
    |> Kconnectex.Connectors.list()
    |> display()
  end

  defp run(%{command: ["connector", "create", connector], url: url}) do
    case read_stdin() do
      {:ok, json} ->
        client(url)
        |> Kconnectex.Connectors.create(connector, json)
        |> display()

      {:error, err} ->
        display_errors([Jason.DecodeError.message(err)])
    end
  end

  defp run(%{command: ["connector", "update", connector], url: url}) do
    case read_stdin() do
      {:ok, json} ->
        client(url)
        |> Kconnectex.Connectors.update(connector, json)
        |> display()

      {:error, err} ->
        display_errors([Jason.DecodeError.message(err)])
    end
  end

  defp run(%{command: ["connector", subcommand, connector], url: url})
       when subcommand in ~w(config delete info pause restart resume status) do
    sub = String.to_atom(subcommand)

    apply(Kconnectex.Connectors, sub, [client(url), connector])
    |> display()
  end

  defp run(opts), do: unknown_command(opts)

  defp client(url), do: Kconnectex.client(url)

  defp display_config(:no_configuration_file) do
    IO.puts("No configuration file found.")
  end

  defp display_config(config) do
    selected = config["selected_cluster"]
    clusters = config["clusters"] || %{}

    if map_size(clusters) > 0 do
      names =
        Enum.map(Map.keys(clusters), fn name ->
          display_name = if name == selected, do: "*#{name}", else: name

          {name, display_name}
        end)

      max = Enum.map(names, fn {_, name} -> String.length(name) end) |> Enum.max()

      Enum.each(names, fn {name, display_name} ->
        cluster = Map.fetch!(clusters, name)
        host = Map.fetch!(cluster, "host")
        port = Map.get(cluster, "port")
        url = if port, do: "#{host}:#{port}", else: host

        IO.puts("#{String.pad_trailing(display_name, max, " ")} #{url}")
      end)
    else
      IO.puts("No environments configured. See `config --help` for more info.")
    end
  end

  defp add_cluster(config, name, host, port \\ nil)

  defp add_cluster(:no_configuration_file, _name, _host, _port) do
    # TODO: create the file?
    IO.puts("No configuration file found.")
  end

  defp add_cluster(config, name, host, port) do
    cluster_config = extract_cluster_config(host, port)
    new_config = put_in(config["clusters"][name], cluster_config)

    case Configuration.write(new_config) do
      :ok ->
        display(:ok)

      {:error, reason} ->
        message = Configuration.format_error(reason)
        display({:error, message})
    end
  end

  defp extract_cluster_config(host, nil), do: %{"host" => host}

  defp extract_cluster_config(host, port) do
    case Integer.parse(port) do
      {port, ""} ->
        %{"host" => host, "port" => port}

      :error ->
        %{"host" => host, "port" => port}
    end
  end

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

  defp display({:error, message}) do
    IO.puts("Error with request:")
    IO.puts(error_description(message))
  end

  defp error_description(message) when is_binary(message) do
    "  #{message}"
  end

  defp error_description(:econnrefused), do: "  Connection to server failed"

  defp error_description(:nxdomain), do: "  Domain not found. Is the cluster reachable?"

  defp error_description(:timeout), do: "  Timed out connecting to server"

  defp error_description(:not_found), do: "  Not found"

  defp error_description(:rebalancing), do: "  Connect is rebalancing. Try again later."

  defp error_description(messages) when is_list(messages) do
    messages
    |> Enum.map(&"  #{&1}")
    |> Enum.join("\n")
  end

  defp display_errors(errors) do
    IO.puts("Here are some errors that need to be resolved:")
    Enum.each(errors, &IO.puts/1)
    IO.puts("")
    IO.puts("Run `#{:escript.script_name()} --help` for usage")
  end

  defp unknown_command(opts) do
    command = Enum.join(opts.command, " ")

    display_errors(["Command `#{command}` was not recognized"])
  end

  defp read_stdin do
    IO.read(:stdio, :all)
    |> String.trim()
    |> Jason.decode()
  end
end
