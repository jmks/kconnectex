defmodule Kconnectex.Util do
  def handle_response(response) do
    case response do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        if body == "", do: :ok, else: body

      {:ok, %{status: 404}} ->
        {:error, :not_found}

      {:ok, %{status: 409}} ->
        {:error, :rebalancing}

      {:ok, %{status: status, body: body}} when status in 400..499 ->
        {:error, body}

      {:error, err} ->
        {:error, err}
    end
  end
end
