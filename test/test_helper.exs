defmodule IntegrationHelpers do
  def connect_client do
    Kconnectex.client("http://0.0.0.0:8083")
  end

  def delete_existing_connectors(client, connectors) do
    to_delete = MapSet.new(connectors)

    {:ok, connectors} = Kconnectex.Connectors.list(client)

    connectors
    |> Enum.filter(&MapSet.member?(to_delete, &1))
    |> Enum.map(&Kconnectex.Connectors.delete(client, &1))
  end
end

ExUnit.configure(exclude: :integration)
ExUnit.start()
