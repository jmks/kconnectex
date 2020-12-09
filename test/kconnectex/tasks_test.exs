defmodule Kconnectex.TasksTest do
  use ExUnit.Case, async: true

  alias Kconnectex.Tasks

  defmodule FakeTasksAdapter do
    def call(%{url: "localhost/connectors/filestream/tasks"}, _) do
      body = [
        %{
          "id" => %{"connector" => "filestream", "task" => 0},
          "config" => %{
            "batch.size" => "2000",
            "file" => "/kafka/LICENSE",
            "task.class" => "org.apache.kafka.connect.file.FileStreamSourceTask",
            "topic" => "license-stream"
          }
        }
      ]

      {:ok, %Tesla.Env{status: 200, body: body}}
    end

    def call(%{url: "localhost/connectors/filestream/tasks/0/status"}, _) do
      body = %{
        "id" => 0,
        "state" => "RUNNING",
        "worker_id" => "172.19.0.4:8083"
      }

      {:ok, %Tesla.Env{status: 200, body: body}}
    end

    def call(%{url: "localhost/connectors/filestream/tasks/9/status"}, _) do
      {:ok, %Tesla.Env{status: 404}}
    end
  end

  test "GET /connectors/:connector/tasks" do
    response = Tasks.list(client(), "filestream")

    assert is_list(response)
    task = hd(response)
    assert Map.has_key?(task, "id")
    assert Map.has_key?(task, "config")
    assert task["id"]["connector"] == "filestream"
    assert task["id"]["task"] == 0
  end

  test "GET /connectors/:connector/tasks/:task/status" do
    response = Tasks.status(client(), "filestream", 0)

    assert response["id"] == 0
    assert response["state"] == "RUNNING"
    assert Map.has_key?(response, "worker_id")
  end

  test "GET /connectors/:connector/tasks/:task/status with unknown task" do
    assert {:error, :not_found} == Tasks.status(client(), "filestream", 9)
  end

  defp client(base_url \\ "localhost") do
    Kconnectex.client(base_url, FakeTasksAdapter)
  end
end
