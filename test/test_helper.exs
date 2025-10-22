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

defmodule Fixtures do
  @path "test/fixtures"

  def fixture(filename) do
    Path.join(@path, filename)
  end
end

defmodule RenderAssertions do
  defmacro assert_rendered(part_or_parts, printed) do
    parts = if is_list(part_or_parts), do: part_or_parts, else: [part_or_parts]

    quote do
      assert Enum.join(unquote(parts), "\n") == String.trim_trailing(unquote(printed), "\n")
    end
  end
end

ExUnit.configure(exclude: :integration)
ExUnit.start()
