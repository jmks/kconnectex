defmodule Kconnectex.CLI.Options do
  alias Kconnectex.CLI.ConfigFile

  @enforce_keys [:config]
  defstruct [:config, url: :unset, help?: false, command: [], errors: []]

  def extract(args) do
    case ConfigFile.read() do
      {:ok, config} ->
        parse(args, config)

      {:error, :no_configuration_file} ->
        opts = parse(args, %{})
        %{opts | config: :no_configuration_file}

      {:error, reason} ->
        {:error, ConfigFile.format_error(reason)}
    end
  end

  def parse(args, config \\ %{}) do
    flags = [cluster: :string, help: :boolean, url: :string]
    {parsed, command, invalid} = OptionParser.parse(args, strict: flags)

    %__MODULE__{
      help?: Keyword.get(parsed, :help, false),
      config: config
    }
    |> with_command(command)
    |> set_url(Keyword.get(parsed, :url), Keyword.get(parsed, :cluster))
    |> invalid_flag_errors(invalid)
  end

  defp set_url(options, url, cluster)

  defp set_url(%{help?: true} = opts, _url, _cluster), do: opts

  defp set_url(%{command: ["config" | _]} = opts, _url, _cluster), do: opts

  defp set_url(opts, url, _cluster) when is_binary(url) do
    %{opts | url: url}
  end

  defp set_url(opts, _url, cluster) when is_binary(cluster) do
    cluster_config = get_in(opts.config, ["clusters", cluster])

    if cluster_config do
      %{opts | url: build_url(cluster_config)}
    else
      missing_cluster_error(opts, cluster)
    end
  end

  defp set_url(opts, _url, _cluster) do
    selected = opts.config["selected_cluster"]
    cluster_config = get_in(opts.config, ["clusters", selected])

    cond do
      selected && is_nil(cluster_config) ->
        %{opts | errors: ["selected cluster #{selected} was not found in the configuration"]}

      cluster_config ->
        %{opts | url: build_url(cluster_config)}

      true ->
        message =
          if map_size(opts.config) == 0 do
            "Either create a configuration file or explictly provide --url"
          else
            "--url is required"
          end

        %{opts | errors: [message | opts.errors]}
    end
  end

  defp missing_cluster_error(opts, target_cluster) do
    if map_size(opts.config) != 0 do
      clusters = get_in(opts.config, ["clusters"])
      cluster_names = if is_map(clusters), do: Map.keys(clusters), else: []

      errors = [
        "The provided --cluster '#{target_cluster}' was not found in the configuration file '#{opts.config.config_file_path}'",
        "That configuration file contains these clusters:"
        | Enum.map(cluster_names, fn cluster -> "  #{cluster}" end)
      ]

      %{opts | errors: errors ++ opts.errors}
    else
      error = "--cluster was provided but no configuration file was found"

      %{opts | errors: [error | opts.errors]}
    end
  end

  defp invalid_flag_errors(opts, invalid) do
    messages =
      invalid
      |> Enum.map(&elem(&1, 0))
      |> Enum.map(fn opt -> "Unknown flag: #{opt}" end)

    %{opts | errors: messages ++ opts.errors}
  end

  defp with_command(opts, []) do
    %{opts | help?: true}
  end

  defp with_command(opts, command) do
    %{opts | command: command}
  end

  defp build_url(config) do
    host = Map.fetch!(config, "host")
    port = Map.get(config, "port")

    if port do
      Enum.join([host, port], ":")
    else
      host
    end
  end
end
