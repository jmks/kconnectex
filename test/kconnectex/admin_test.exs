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

  test "PUT /admin/loggers/:logger" do
    assert Kconnectex.Admin.logger_level(client(), "root", "DEBUG") == [
             "root"
           ]
  end

  @tag :integration
  test "loggers" do
    import IntegrationHelpers

    # Reset to defaults; previous test runs may have changed them
    Kconnectex.Admin.logger_level(connect_client(), "root", "INFO")
    Kconnectex.Admin.logger_level(connect_client(), "org.reflections", "WARN")

    loggers = Kconnectex.Admin.loggers(connect_client())
    assert %{"org.reflections" => %{"level" => "WARN"}, "root" => %{"level" => "INFO"}} = loggers

    level = Kconnectex.Admin.logger_level(connect_client(), "root")
    assert %{"level" => "INFO"} = level

    Kconnectex.Admin.logger_level(connect_client(), "root", "DEBUG")

    level = Kconnectex.Admin.logger_level(connect_client(), "root")
    assert %{"level" => "DEBUG"} = level
  end

  defp client(base_url \\ "localhost") do
    Kconnectex.client(base_url, FakeAdapter)
  end
end
