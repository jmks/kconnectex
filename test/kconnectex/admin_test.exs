defmodule Kconnectex.AdminTest do
  use ExUnit.Case, async: true

  defmodule FakeAdapter do
    def call(%{method: :put, url: "localhost/admin/loggers/root"}, _) do
      {:ok,
       %Tesla.Env{
         status: 200,
         body: ["root"]
       }}
    end
  end

  @tag :integration
  test "GET /admin/loggers" do
    import IntegrationHelpers

    loggers = Kconnectex.Admin.loggers(connect_client())

    assert  %{"org.reflections" => %{"level" => "ERROR"}, "root" => %{"level" => "INFO"}} = loggers
  end

  @tag :integration
  test "GET /admin/loggers/:logger" do
    import IntegrationHelpers

    level = Kconnectex.Admin.logger_level(connect_client(), "root")

    assert %{"level" => "INFO"} = level
  end

  test "PUT /admin/loggers/:logger" do
    assert Kconnectex.Admin.logger_level(client(), "root", "DEBUG") == [
      "root"
    ]
  end

  @tag :integration
  test "PUT /admin/loggers/:logger integration" do
    import IntegrationHelpers

    Kconnectex.Admin.logger_level(connect_client(), "root", "DEBUG")

    level = Kconnectex.Admin.logger_level(client(), "root")
    assert %{"level" => "DEBUG"} = level
  end

  defp client(base_url \\ "localhost") do
    Kconnectex.client(base_url, FakeAdapter)
  end
end
