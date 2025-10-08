defmodule Kconnectex.AdminTest do
  use ExUnit.Case, async: true

  alias Kconnectex.Admin

  defmodule FakeAdapter do
    def call(%{method: :put, url: "localhost/admin/loggers/root"}, _) do
      {:ok, %Tesla.Env{status: 200, body: ["root"]}}
    end
  end

  test "PUT /admin/loggers/:logger" do
    assert {:ok, ["root"]} == Admin.logger_level(client(), "root", "DEBUG")
  end

  test "logger must be present" do
    assert {:error, ["logger must be present"]} == Admin.logger_level(client(), "")
    assert {:error, ["logger must be present"]} == Admin.logger_level(client(), " \r\n ", "ERROR")
  end

  test "logger must be a valid level" do
    assert {:error, [error]} = Admin.logger_level(client(), "io.debezium", "BANANA")
    assert String.starts_with?(error, "level must be one of")
  end

  @tag :integration
  test "loggers" do
    import IntegrationHelpers

    # Reset to known values; previous test runs may have changed them
    Admin.logger_level(
      connect_client(),
      "org.apache.kafka.clients.admin.KafkaAdminClient",
      "INFO"
    )

    Admin.logger_level(
      connect_client(),
      "org.reflections",
      "WARN"
    )

    {:ok, loggers} = Admin.loggers(connect_client())

    assert loggers["org.reflections"]["level"] == "WARN"
    assert loggers["org.apache.kafka.clients.admin.KafkaAdminClient"]["level"] == "INFO"

    {:ok, level} =
      Admin.logger_level(connect_client(), "org.apache.kafka.clients.admin.KafkaAdminClient")

    assert %{"level" => "INFO"} = level

    Admin.logger_level(
      connect_client(),
      "org.apache.kafka.clients.admin.KafkaAdminClient",
      "DEBUG"
    )

    {:ok, level} =
      Admin.logger_level(connect_client(), "org.apache.kafka.clients.admin.KafkaAdminClient")

    assert %{"level" => "DEBUG"} = level
  end

  defp client(base_url \\ "localhost") do
    Kconnectex.client(base_url, FakeAdapter)
  end
end
