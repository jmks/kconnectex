defmodule Kconnectex.CLI.Options do
  alias Kconnectex.CLI.Configuration

  @enforce_keys [:config]
  defstruct [:config, url: :no_configuration, help?: false, command: [], errors: []]

  @default_port 8083

  def extract(args) do
    case Configuration.load() do
      {:ok, config} ->
        parse(args, config)

      {:error, :no_configuration_file} ->
        opts = parse(args, %{})
        %{opts | config: :no_configuration_file}

      config_error ->
        config_error
    end
  end

  def parse(args, config \\ %{}) do
    flags = [url: :string, help: :boolean, cluster: :string]
    {parsed, command, invalid} = OptionParser.parse(args, strict: flags)

    %__MODULE__{
      help?: Keyword.get(parsed, :help, false),
      config: config
    }
    |> with_command(command)
    |> set_url(Keyword.get(parsed, :url, :no_url), Keyword.get(parsed, :cluster, :no_cluster))
    |> add_errors(invalid)
  end

  defp set_url(options, url, cluster)

  defp set_url(%{help?: true} = opts, :no_url, :no_cluster), do: opts

  defp set_url(%{command: ["config" | _]} = opts, :no_url, :no_cluster), do: opts

  defp set_url(opts, url, cluster) when url != :no_url and cluster != :no_cluster do
    %{opts | errors: ["Do not specify both --cluster and --url" | opts.errors]}
  end

  defp set_url(opts, url, cluster) do
    case select_cluster(cluster, opts.config) do
      {:ok, host, port} ->
        %{opts | url: "#{host}:#{port}"}

      {:ok, :use_url} ->
        if url == :no_url do
          %{opts | errors: ["--url is required" | opts.errors]}
        else
          %{opts | url: url}
        end

      {:error, :invalid_cluster, bad_cluster} ->
        %{opts | errors: ["Cluster #{bad_cluster} was not found in the configuration"]}

      {:error, :invalid_config, bad_cluster} ->
        %{opts | errors: ["Selected cluster #{bad_cluster} was not found in the configuration"]}
    end
  end

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

  defp select_cluster(:no_cluster, config) do
    use_selected_cluster(config)
  end

  defp select_cluster(cluster, config) do
    cluster_env = get_in(config, ["env", cluster])

    if cluster_env do
      {:ok, Map.fetch!(cluster_env, "host"), Map.get(cluster_env, "port", @default_port)}
    else
      {:error, :invalid_cluster, cluster}
    end
  end

  defp use_selected_cluster(config) do
    selected = get_in(config, ["global", "selected_env"])
    selected_env = get_in(config, ["env", selected])

    cond do
      selected && is_nil(selected_env) ->
        {:error, :invalid_config, selected}

      selected_env ->
        {:ok, Map.fetch!(selected_env, "host"), Map.get(selected_env, "port", @default_port)}

      true ->
        {:ok, :use_url}
    end
  end
end
