defmodule Kconnectex.CLI.ConfigFile do
  @filename ".kconnectex.json"

  def read(filepath \\ :use_home_or_local) do
    with {:ok, file} <- config_filepath(filepath),
         true <- File.regular?(file),
         {:ok, contents} <- File.read(file),
         {:ok, json} <- Jason.decode(contents),
         {:ok, config} <- validate_config(json) do
      {:ok, Map.put(config, :config_file_path, file)}
    else
      false ->
        {:error, :no_configuration_file}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def validate_config(config) do
    with :ok <- validate_app_settings(config),
         :ok <- validate_clusters(config) do
      {:ok, config}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  def write(config, filepath \\ :use_home_or_local) do
    config = Map.delete(config, :config_file_path)

    with {:ok, validated} <- validate_config(config),
         {:ok, json} <- Jason.encode(validated, pretty: true),
         {:ok, file} <- config_filepath(filepath),
         {:ok, io} <- File.open(file, [:write]),
         :ok <- IO.write(io, json),
         :ok <- File.close(io) do
      :ok
    else
      {:error, error} ->
        {:error, error}
    end
  end

  def format_error(reason)

  def format_error(:no_configuration_file) do
    parts = [
      "Could not find configuration file",
      "Looked for: "
      | Enum.map(default_files(), fn msg -> "  #{msg}" end)
    ]

    Enum.join(parts, "\n")
  end

  def format_error({:missing_cluster, cluster}) do
    "selected cluster #{cluster} does not exist under key 'clusters'"
  end

  def format_error({:missing_host, cluster}) do
    "cluster #{cluster} must specify a host"
  end

  def format_error({:nonbinary_host, cluster}) do
    "cluster #{cluster} host must be a string"
  end

  def format_error({:noninteger_port, cluster}) do
    "cluster #{cluster} port must be an integer"
  end

  defp config_filepath(:use_home_or_local) do
    files = Enum.filter(default_files(), &File.regular?/1)

    if Enum.any?(files) do
      {:ok, hd(files)}
    else
      {:error, :no_configuration_file}
    end
  end

  defp config_filepath(provided), do: {:ok, provided}

  defp default_files do
    [System.user_home(), File.cwd!()]
    |> Enum.filter(& &1)
    |> Enum.map(fn dir -> Path.join([dir, @filename]) end)
  end

  defp validate_app_settings(%{"selected_cluster" => cluster, "clusters" => clusters}) do
    if Map.has_key?(clusters, cluster) do
      :ok
    else
      {:error, {:missing_cluster, cluster}}
    end
  end

  defp validate_app_settings(_), do: :ok

  defp validate_clusters(%{"clusters" => clusters}) do
    clusters
    |> Enum.map(&validate_cluster/1)
    |> Enum.find(:ok, fn
      {:error, _} -> true
      :ok -> false
    end)
  end

  defp validate_clusters(_), do: :ok

  defp validate_cluster({cluster, data}) do
    cond do
      not Map.has_key?(data, "host") ->
        {:error, {:missing_host, cluster}}

      not is_binary(data["host"]) ->
        {:error, {:nonbinary_host, cluster}}

      Map.has_key?(data, "port") and not is_integer(data["port"]) ->
        {:error, {:noninteger_port, cluster}}

      true ->
        :ok
    end
  end
end
