defmodule Kconnectex.CLI.Options do
  alias Kconnectex.CLI.ConfigFile

  @enforce_keys [:config]
  defstruct [:config, url: :unset, help?: false, format: :text, command: [], options: [], errors: []]

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
    global_flags = [cluster: :string, help: :boolean, url: :string, json: :boolean]

    command_flags = [
      # connectors
      expand: :string,
      # connector restart
      only_failed: :boolean,
      include_tasks: :boolean,
    ]

    {parsed, command, invalid} = OptionParser.parse(args, strict: global_flags ++ command_flags)

    %__MODULE__{
      help?: Keyword.get(parsed, :help, false),
      format: if(Keyword.get(parsed, :json, false), do: :json, else: :text),
      config: config
    }
    |> with_command(command, extract_flags(parsed, command_flags))
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
      |> Enum.map(fn
        flag when is_atom(flag) ->
          as_flag = flag |> to_string() |> String.replace("_", "-")

          "--#{as_flag}"

        str ->
          str
      end)
      |> Enum.map(fn opt -> "Unknown flag: #{opt}" end)

    %{opts | errors: messages ++ opts.errors}
  end

  defp with_command(opts, [], _flags) do
    %{opts | help?: true}
  end

  defp with_command(opts, command = ["connectors"], flags) do
    expands =
      flags
      |> Keyword.get(:expand, "")
      |> String.split(",", trim: true)
      |> Enum.map(fn
        "info" -> :info
        "status" -> :status
        unknown -> {:error, unknown}
      end)

    error = Enum.find(expands, &match?({:error, _}, &1))
    opts = invalid_flag_errors(opts, Keyword.delete(flags, :expand))

    if error do
      {:error, unknown} = error
      message = "Unknown value for --expand: #{unknown}"

      %{opts | command: command, errors: [message | opts.errors]}
    else
      expand = if length(expands) == 1, do: hd(expands), else: expands

      %{opts | command: command, options: [expand: expand]}
    end
  end

  defp with_command(opts, command = ["connector", "restart" | _], flags) do
    only_failed? = Keyword.get(flags, :only_failed, false)
    include_tasks? = Keyword.get(flags, :include_tasks, false)

    new_options = opts.options

    new_options =
      if only_failed?, do: Keyword.put(new_options, :only_failed, true), else: new_options

    new_options =
      if include_tasks?, do: Keyword.put(new_options, :include_tasks, true), else: new_options

    new_flags =
      flags
      |> Keyword.delete(:only_failed)
      |> Keyword.delete(:include_tasks)

    new_opts = invalid_flag_errors(opts, new_flags)

    %{new_opts | command: command, options: new_options}
  end

  defp with_command(opts, command, flags) do
    %{opts | command: command}
    |> invalid_flag_errors(flags)
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

  defp extract_flags(options, spec) do
    flags = Enum.map(spec, &elem(&1, 0))

    Enum.filter(options, fn {flag, _} -> flag in flags end)
  end
end
