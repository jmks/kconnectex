defmodule Kconnectex do
  @moduledoc """
  Documentation for `Kconnectex`.
  """

  def client(url, adapter \\ Tesla.Adapter.Hackney) do
    middleware = [
      {Tesla.Middleware.BaseUrl, url},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers,
       [
         {"accept", "application/json"},
         {"content-type", "application/json"}
       ]}
    ]

    Tesla.client(middleware, adapter)
  end
end
