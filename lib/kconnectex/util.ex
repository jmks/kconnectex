defmodule Kconnectex.Util do
  def handle_response(response) do
    case response do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        if body == "", do: :ok, else: {:ok, body}

      {:ok, %{status: 404}} ->
        {:error, :not_found}

      {:ok, %{status: 409}} ->
        {:error, :rebalancing}

      {:ok, %{status: status, body: body}} when status in 400..599 ->
        {:error, body}

      {:error, err} ->
        {:error, err}
    end
  end

  def validate(validations) do
    do_validate(validations, [])
  end

  defp do_validate([], []), do: :ok

  defp do_validate([], errors), do: {:error, errors |> List.flatten |> Enum.reverse}

  defp do_validate([{field, checks} | rest], errors) do
    case failed_conditions(field, checks) do
      [] ->
        do_validate(rest, errors)
      errs ->
        do_validate(rest, [errs | errors])
    end
  end

  defp failed_conditions(field, checks) do
    checks
    |> Enum.map(fn condition ->
      case check(condition) do
        :ok -> :ok
        {:error, err} -> {field, err}
      end
    end)
    |> Enum.filter(&(&1 != :ok))
  end

  defp check({:present, ""}), do: {:error, :is_blank}
  defp check({:present, __}), do: :ok

  defp check({:match, value, value}), do: :ok
  defp check({:match, _, _}), do: {:error, :do_not_match}
end
