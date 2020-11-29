defmodule Kconnectex.Util do
  def handle_response(response) do
    case response do
      %{status: status, body: ""} when status in [200, 202] ->
        :ok

      %{status: 200, body: body} ->
        case Jason.decode(body) do
          {:ok, json} -> json
          otherwise -> otherwise
        end

      %{status: 409} ->
        {:error, :rebalancing}

      {:error, err} ->
        {:error, err}

      env ->
        {:error, env}
    end
  end
end
