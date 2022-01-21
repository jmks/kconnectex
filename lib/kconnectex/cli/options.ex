defmodule Kconnectex.CLI.Options do
  alias Kconnectex.CLI.Configuration

  @enforce_keys [:config]
  defstruct [:config, url: :no_configuration, help?: false, command: [], errors: []]

  def extract(args) do
    case Configuration.load() do
      {:ok, config} ->
        parse(args, config)

      {:error, :no_configuration_file} ->
        opts = parse(args, %{})
        %{opts | config: :no_configuration_file}

      {:error, reason} ->
        {:error, Configuration.format_error(reason)}
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

  defp set_url(opts, _url, cluster) when not is_nil(cluster) do
    cluster_config = get_in(opts.config, ["clusters", cluster])

    if cluster_config do
      %{opts | url: url(cluster_config)}
    else
      actual_clusters = Map.keys(opts.config["clusters"])

      errors = [
        "The provided --cluster '#{cluster}' was not found in the configuration file '#{opts.config.config_file_path}'",
        "That configuration file contains these clusters:"
        | Enum.map(actual_clusters, fn cluster -> "  #{cluster}" end)
      ]

      %{opts | errors: errors}
    end
  end

  defp set_url(opts, _url, _cluster) do
    selected = opts.config["selected_cluster"]
    cluster_config = get_in(opts.config, ["clusters", selected])

    cond do
      selected && is_nil(cluster_config) ->
        %{opts | errors: ["selected cluster #{selected} was not found in the configuration"]}

      cluster_config ->
        %{opts | url: url(cluster_config)}

      true ->
        message =
          if map_size(opts.config) == 0 do
            "Either create a configuration file or explictly use the --url option"
          else
            "--url is required"
          end

        %{opts | errors: [message | opts.errors]}
    end
  end

  defp invalid_flag_errors(opts, invalid) do
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

  defp url(config) do
    host = Map.fetch!(config, "host")
    port = Map.get(config, "port")

    if port do
      Enum.join([host, port], ":")
    else
      host
    end
  end
end
