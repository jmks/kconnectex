defmodule Kconnectex.CLI do
  alias Kconnectex.CLI.{ConfigFile, Options, Table}
  alias Kconnectex.CLI.Watcher

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
      ["plugin" | _] -> help(:plugins)
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
          |> ConfigFile.write()
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
          |> ConfigFile.write()
          |> display()
        else
          display(:ok)
        end
    end
  end

  defp run(%{command: ["cluster"]} = opts) do
    run(Map.put(opts, :command, ["cluster", "info"]))
  end

  defp run(%{command: ["cluster", "info"], url: url}) do
    client(url)
    |> Kconnectex.Cluster.info()
    |> display()
  end

  defp run(%{command: ["cluster", "health"], url: url}) do
    client(url)
    |> Kconnectex.Cluster.health()
    |> display()
  end

  defp run(%{command: ["loggers"], url: url, format: :text}) do
    case Kconnectex.Admin.loggers(client(url)) do
      {:ok, loggers} ->
        values = Kconnectex.CLI.Commands.Loggers.extract(loggers)

        Kconnectex.CLI.Commands.Loggers.headers()
        |> Table.new(values)
        |> Table.render()
        |> IO.puts()

      otherwise ->
        display(otherwise)
    end
  end

  defp run(%{command: ["loggers"], url: url, format: :json}) do
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

  defp run(options = %{command: ["plugin", "validate"], url: url}) do
    case read_stdin() do
      {:ok, json} ->
        client(url)
        |> Kconnectex.ConnectorPlugins.validate_config(json)
        |> extract_errors(options)
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

  defp run(opts = %{command: ["connectors"]}) do
    %{url: url, options: options} = opts

    client(url)
    |> Kconnectex.Connectors.list(options)
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

  # If no connector is selected, but there is only a single connector, use that one.
  defp run(%{command: ["connector", subcommand], url: url} = opts)
       when subcommand in ~w(config delete info pause resume status) do
    case Kconnectex.Connectors.list(client(url)) do
      {:ok, [connector]} ->
        new_opts = %{opts | command: opts.command ++ [connector]}

        run(new_opts)

      {:ok, connectors} ->
        choices = Enum.map(connectors, fn c -> "  * #{c}" end) |> Enum.join("\n")

        message = """
        There are #{length(connectors)} connectors present. Please provide one of:
        #{choices}
        """

        display({:error, message})

      {:error, reason} ->
        display({:error, reason})
    end
  end

  # TODO: this breaks the above pattern -- when a single connector exists
  # it will use that if the name is not provided.
  # I may remove that feature in favour of a --watch option
  defp run(opts = %{command: ["connector", "restart", connector]}) do
    opts.url
    |> client()
    |> Kconnectex.Connectors.restart(connector, opts.options)
    |> display()
  end

  # --watch is always text
  defp run(%{command: ["connector", "status", connector], url: url, watch?: true}) do
    # prime the rendering, so we can render with headers
    {:ok, status} = Kconnectex.Connectors.status(client(url), connector)
    values = Kconnectex.CLI.Commands.Connectors.extract(status)
    headers = Kconnectex.CLI.Commands.Connectors.headers()
    table = Table.new(headers, values)
    IO.puts(Table.render(table))

    Watcher.start_link(
      values: values,
      call: fn -> Kconnectex.Connectors.status(client(url), connector) end,
      transform: &Kconnectex.CLI.Commands.Connectors.extract/1,
      render: &Table.render_rows(table, &1)
    )

    # TODO: System.no_halt(true) not working here?
    :timer.sleep(:infinity)
  end

  defp run(%{command: ["connector", "status", connector], url: url, format: :text}) do
    case Kconnectex.Connectors.status(client(url), connector) do
      {:ok, status} ->
        values = Kconnectex.CLI.Commands.Connectors.extract(status)

        Kconnectex.CLI.Commands.Connectors.headers()
        |> Table.new(values)
        |> Table.render()
        |> IO.puts()

      otherwise ->
        display(otherwise)
    end
  end

  defp run(%{command: ["connector", subcommand, connector], url: url})
       when subcommand in ~w(config delete info pause resume status) do
    apply(Kconnectex.Connectors, String.to_atom(subcommand), [client(url), connector])
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

  defp add_cluster(config, name, host, port \\ 8083)

  defp add_cluster(:no_configuration_file, _name, _host, _port) do
    # TODO: create the file?
    IO.puts("No configuration file found.")
  end

  defp add_cluster(config, name, host, port) do
    new_config = put_in(config["clusters"][name], cluster_config(host, port))

    case ConfigFile.write(new_config) do
      :ok ->
        display(:ok)

      {:error, reason} ->
        message = ConfigFile.format_error(reason)
        display({:error, message})
    end
  end

  defp cluster_config(host, port) do
    maybe_integer =
      case Integer.parse(port) do
        {int, ""} -> int
        _ -> port
      end

    %{"host" => host, "port" => maybe_integer}
  end

  defp display(:ok), do: IO.puts("Success")

  defp display({:text, lines}) do
    Enum.each(lines, &IO.puts/1)
  end

  defp display({:ok, result}) do
    result
    |> Jason.encode!(pretty: true)
    |> IO.puts()
  end

  defp display({:error, %{"message" => message}}) do
    IO.puts(:stderr, "Error with request:")
    IO.puts(:stderr, error_description([message]))
  end

  defp display({:error, message}) do
    IO.puts(:stderr, "Error with request:")
    IO.puts(:stderr, error_description(message))
  end

  defp error_description(message) when is_binary(message) do
    "  #{message}"
  end

  defp error_description(:econnrefused), do: "  Connection to server failed"
  defp error_description(:closed), do: "  Connection to server closed"
  defp error_description(:nxdomain), do: "  Domain not found. Is the cluster reachable?"
  defp error_description(:timeout), do: "  Timed out connecting to server"
  defp error_description(:not_found), do: "  Not found"
  defp error_description(:rebalancing), do: "  Connect is rebalancing. Try again later."

  defp error_description(messages) when is_list(messages) do
    messages
    |> Enum.map(&"  #{&1}")
    |> Enum.join("\n")
  end

  defp error_description(unknown) do
    """
      An unknown error occurred:
      #{inspect(unknown)}
    """
  end

  defp display_errors(errors) do
    IO.puts(:stderr, "Here are some errors that need to be resolved:")
    Enum.each(errors, &IO.puts(:stderr, &1))

    IO.puts("Run `#{:escript.script_name()} --help` for usage")
  end

  defp unknown_command(opts) do
    command = Enum.join(opts.command, " ")

    display_errors(["Command `#{command}` was not recognized"])
  end

  defp read_stdin do
    IO.read(:stdio, :eof)
    |> String.trim()
    |> Jason.decode()
  end

  defp extract_errors({:error, reason}, _options), do: {:error, reason}

  defp extract_errors({:ok, result}, %{format: :text}) do
    configs_with_error =
      Enum.filter(result["configs"], fn config ->
        Enum.any?(get_in(config, ["value", "errors"]))
      end)

    if Enum.any?(configs_with_error) do
      name_errors =
        Enum.flat_map(configs_with_error, fn config ->
          Enum.map(config["value"]["errors"], fn error ->
            [config["value"]["name"], error]
          end)
        end)

      # TODO: Table?
      table = [["CONFIG", "ERROR"] | name_errors]
      width = table |> Enum.map(&hd/1) |> Enum.map(&String.length/1) |> Enum.max()

      formatted =
        Enum.map(table, fn [name, error] ->
          String.pad_trailing(name, width + 3) <> error
        end)

      {:text, formatted}
    else
      {:ok, "No errors"}
    end
  end

  defp extract_errors({:ok, result}, _options) do
    {:ok, result}
  end
end
