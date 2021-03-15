defmodule Kconnectex.CLI.Options do
  defstruct url: :no_configuration,
            cluster: :no_configuration,
            help?: false,
            command: [],
            config: :no_configuration,
            errors: []

  @default_port 8083

  def parse(args) do
    flags = [url: :string, help: :boolean, cluster: :string]
    {parsed, command, invalid} = OptionParser.parse(args, strict: flags)

    %__MODULE__{}
    |> set_help(Keyword.get(parsed, :help, false))
    |> with_command(command)
    |> set_cluster(Keyword.get(parsed, :url), Keyword.get(parsed, :cluster))
    |> add_errors(invalid)
  end

  def update(opts, {:ok, config}) do
    selected = get_in(config, ["global", "selected_env"])
    host = get_in(config, ["env", selected, "host"])
    port = get_in(config, ["env", selected, "port"]) || @default_port

    if selected do
      %{
        opts
        | url: "#{host}:#{port}",
          errors: Enum.reject(opts.errors, &String.contains?(&1, "--url")),
          config: config
      }
    else
      opts
    end
  end

  def update(opts, _) do
    opts
  end

  defp set_help(opts, help), do: %{opts | help?: help}

  defp set_cluster(%{help?: true} = opts, nil, nil), do: opts

  defp set_cluster(%{command: ["config" | _]} = opts, nil, nil), do: opts

  defp set_cluster(opts, nil, nil) do
    %{opts | errors: ["--url is required" | opts.errors]}
  end

  defp set_cluster(opts, url, _) when not is_nil(url), do: %{opts | url: url}

  defp set_cluster(opts, nil, cluster) when not is_nil(cluster), do: %{opts | cluster: cluster}

  defp add_errors(opts, invalid) do
    messages =
      invalid
      |> Enum.map(&elem(&1, 0))
      |> Enum.map(fn opt -> "#{opt} is not valid" end)

    %{opts | errors: messages ++ opts.errors}
  end

  defp with_command(opts, []) do
    %{opts | help?: true}
  end

  defp with_command(opts, command) do
    %{opts | command: command}
  end
end
