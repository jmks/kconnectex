defmodule Kconnectex.TasksTest do
  use ExUnit.Case, async: true

  alias Kconnectex.Tasks

  defmodule FakeTasksAdapter do
    def call(%{url: "localhost/connectors/filestream/tasks" <> _}, _) do
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
      {
        :ok,
        %Tesla.Env{status: 200, body: body}
      }
    end
  end

  test "GET /conncetors/:connector/tasks" do
    response = Tasks.list(client(), "filestream")

    assert is_list(response)
    task = hd(response)
    assert Map.has_key?(task, "id")
    assert Map.has_key?(task, "config")
    assert task["id"]["connector"] == "filestream"
    assert task["id"]["task"] == 0
  end

  defp client(base_url \\ "localhost") do
    Kconnectex.client(base_url, FakeTasksAdapter)
  end
end
