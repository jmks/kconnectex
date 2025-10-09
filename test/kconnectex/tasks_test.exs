defmodule Kconnectex.TasksTest do
  use ExUnit.Case, async: true

  alias Kconnectex.Tasks

  defmodule FakeTasksAdapter do
    def call(%{method: :get, url: "localhost/connectors/filestream/tasks"}, _) do
      body = [
        %{
          "id" => %{"connector" => "filestream", "task" => 0},
          "config" => %{
            "batch.size" => "2000",
            "file" => "/usr/share/doc/kafka/LICENSE",
            "task.class" => "org.apache.kafka.connect.file.FileStreamSourceTask",
            "topic" => "license-stream"
          }
        }
      ]

      {:ok, %Tesla.Env{status: 200, body: body}}
    end

    def call(%{method: :get, url: "localhost/connectors/filestream/tasks/0/status"}, _) do
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

    def call(%{method: :post, url: "localhost/connectors/filestream/tasks/0/restart"}, _) do
      {:ok, %Tesla.Env{status: 204, body: ""}}
    end
  end

  test "connector is required" do
    assert {:error, ["connector can not be blank"]} == Tasks.list(client(), "")
    assert {:error, ["connector can not be blank"]} == Tasks.status(client(), "", 0)
    assert {:error, ["connector can not be blank"]} == Tasks.restart(client(), "", 0)
  end

  test "GET /connectors/:connector/tasks" do
    {:ok, tasks} = Tasks.list(client(), "filestream")

    assert is_list(tasks)
    task = hd(tasks)
    assert Map.has_key?(task, "id")
    assert Map.has_key?(task, "config")
    assert task["id"]["connector"] == "filestream"
    assert task["id"]["task"] == 0
  end

  test "GET /connectors/:connector/tasks/:task_id/status" do
    {:ok, status} = Tasks.status(client(), "filestream", 0)

    assert status["id"] == 0
    assert status["state"] == "RUNNING"
    assert Map.has_key?(status, "worker_id")
  end

  test "GET /connectors/:connector/tasks/:task_id/status with unknown task" do
    assert {:error, :not_found} == Tasks.status(client(), "filestream", 9)
  end

  test "POST /connectors/:connector/tasks/:task_id/restart" do
    assert :ok == Tasks.restart(client(), "filestream", 0)
  end

  defp client(base_url \\ "localhost") do
    Kconnectex.client(base_url, FakeTasksAdapter)
  end
end
