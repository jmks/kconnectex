defmodule Kconnectex.CLI.Configuration do
  @config_filename ".kconnectex.toml"

  def load(filepath \\ :use_home_or_local) do
    with {:ok, file} <- config_file(filepath),
         {:ok, config} <- Toml.decode_file(file),
         {:ok, config} <- validate_config(config) do
      {:ok, config}
    else
      {:error, error} when is_list(error) or is_binary(error) ->
        {:error, error}
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

  defp config_file(:use_home_or_local) do
    files = default_files() |> Enum.filter(&File.exists?/1)

    if Enum.any?(files) do
      {:ok, hd(files)}
    else
      message = [
        "could not find configuration file",
        "Looked for: "
        | default_files() |> Enum.map(fn msg -> "  #{msg}" end)
      ]

      {:error, message}
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
      {:error,
       "Selected environment #{env} does not exist as table [env.#{env}]. Add the table or change the selected_env."}
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
        {:error, "host is required"}

      not is_binary(env["host"]) ->
        {:error, "host must be a string"}

      Map.has_key?(env, "port") and not is_integer(env["port"]) ->
        {:error, "port must be an integer"}

      true ->
        :ok
    end
  end
end
