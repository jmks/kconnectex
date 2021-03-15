defmodule Kconnectex.CLI do
  alias Kconnectex.CLI.{Configuration, Options}

  import Kconnectex.CLI.Help

  @default_port 8083

  def main(args) do
    opts =
      args
      |> Options.parse()
      |> Options.update(Configuration.load())

    case opts.errors do
      [] ->
        run(opts)

      errors ->
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

  defp display_config(:no_configuration) do
    IO.puts("No configuration file found.")
  end

  defp display_config(config) do
    selected = get_in(config, ["global", "selected_env"])
    envs = get_in(config, ["env"]) || %{}

    if map_size(envs) > 0 do
      names =
        Enum.map(Map.keys(envs), fn name ->
          display_name = if name == selected, do: "*#{name}", else: name

          {name, display_name}
        end)

      max = Enum.map(names, fn {_, name} -> String.length(name) end) |> Enum.max()

      Enum.each(names, fn {name, display_name} ->
        env = Map.fetch!(envs, name)
        host = Map.fetch!(env, "host")
        port = Map.get(env, "port", @default_port)

        IO.puts("#{String.pad_trailing(display_name, max, " ")} #{host}:#{port}")
      end)
    else
      IO.puts("No environments configured. See `config --help` for more info.")
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
