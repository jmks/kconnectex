defmodule IntegrationHelpers do
  def connect_client do
    Kconnectex.client("http://0.0.0.0:8083")
  end
end

ExUnit.configure(exclude: :integration)
ExUnit.start()
