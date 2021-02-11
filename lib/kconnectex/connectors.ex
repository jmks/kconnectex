defmodule Kconnectex.Connectors do
  alias Kconnectex.Request

  def list(client) do
    client
    |> Request.new()
    |> Request.get("/connectors")
    |> Request.execute()
  end

  def create(client, connector, config) do
    request(client, connector)
    |> Request.post("/connectors", %{name: connector, config: config})
    |> Request.execute()
  end

  def info(client, connector) do
    request(client, connector)
    |> Request.get("/connectors/#{connector}")
    |> Request.execute()
  end

  def config(client, connector) do
    request(client, connector)
    |> Request.get("/connectors/#{connector}/config")
    |> Request.execute()
  end

  def update(client, connector, config) do
    request(client, connector)
    |> Request.put("/connectors/#{connector}/config", config)
    |> Request.execute()
  end

  def status(client, connector) do
    request(client, connector)
    |> Request.get("/connectors/#{connector}/status")
    |> Request.execute()
  end

  def restart(client, connector) do
    request(client, connector)
    |> Request.post("/connectors/#{connector}/restart", "")
    |> Request.execute()
  end

  def pause(client, connector) do
    request(client, connector)
    |> Request.put("/connectors/#{connector}/pause", "")
    |> Request.execute()
  end

  def resume(client, connector) do
    request(client, connector)
    |> Request.put("/connectors/#{connector}/resume", "")
    |> Request.execute()
  end

  def delete(client, connector) do
    request(client, connector)
    |> Request.delete("/connectors/#{connector}")
    |> Request.execute()
  end

  defp request(client, connector) do
    client
    |> Request.new()
    |> Request.validate({:present, connector}, "connector can not be blank")
  end
end
