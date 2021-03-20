defmodule Kconnectex.CLI.Configuration do
  @config_filename ".kconnectex.toml"

  def load(filepath \\ :use_home_or_local) do
    with {:ok, file} <- config_file(filepath),
         {:ok, config} <- Toml.decode_file(file),
         {:ok, config} <- validate_config(config) do
      {:ok, config}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def validate_config(config) do
    with :ok <- validate_global_config(config),
         :ok <- validate_envs(config) do
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

  def format_error({:missing_environment, env}) do
    "Selected environment #{env} does not exist as table [env.#{env}]. Add the table or change the selected_env."
  end

  def format_error(:missing_host), do: "host is required"

  def format_error(:nonbinary_host), do: "host must be a string"

  def format_error(:noninteger_port), do: "port must be an integer"

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

  defp validate_global_config(%{"global" => %{"selected_env" => env}, "env" => envs}) do
    if Map.has_key?(envs, env) do
      :ok
    else
      {:error, {:missing_environment, env}}
    end
  end

  defp validate_global_config(_), do: :ok

  defp validate_envs(%{"env" => envs}) do
    envs
    |> Map.values()
    |> Enum.map(&validate_env/1)
    |> Enum.find(:ok, fn
      {:error, _} -> true
      :ok -> false
    end)
  end

  defp validate_envs(_), do: :ok

  defp validate_env(env) do
    cond do
      not Map.has_key?(env, "host") ->
        {:error, :missing_host}

      not is_binary(env["host"]) ->
        {:error, :nonbinary_host}

      Map.has_key?(env, "port") and not is_integer(env["port"]) ->
        {:error, :noninteger_port}

      true ->
        :ok
    end
  end
end
