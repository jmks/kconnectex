defmodule Kconnectex.CLI.Configuration do
  @config_filename ".kconnectex.json"

  def load(filepath \\ :use_home_or_local) do
    with {:ok, file} <- config_file(filepath),
         {:ok, contents} <- File.read(file),
         {:ok, json} <- Jason.decode(contents),
         {:ok, config} <- validate_config(json) do
      {:ok, config}
    else
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

  def format_error(:enoent), do: "file not found"

  defp config_file(:use_home_or_local) do
    files = Enum.filter(default_files(), &File.exists?/1)

    if Enum.any?(files) do
      {:ok, hd(files)}
    else
      {:error, :no_configuration_file}
    end
  end

  defp config_file(provided), do: {:ok, provided}

  defp default_files do
    [System.user_home(), File.cwd!()]
    |> Enum.filter(& &1)
    |> Enum.map(fn dir -> Path.join([dir, @config_filename]) end)
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
