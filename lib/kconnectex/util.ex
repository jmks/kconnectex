defmodule Kconnectex.Util do
  def handle_response(response) do
    case response do
      {:ok, %{status: status, body: ""}} when status in [200, 202] ->
        :ok

      {:ok, %{status: 200, body: body}} ->
        body

      {:ok, %{status: 409}} ->
        {:error, :rebalancing}

      {:error, err} ->
        {:error, err}
    end
  end
end
