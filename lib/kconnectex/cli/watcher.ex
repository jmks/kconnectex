defmodule Kconnectex.CLI.Watcher do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    state = %{
      # parameters
      call: Keyword.fetch!(opts, :call),
      transform: Keyword.fetch!(opts, :transform),
      render: Keyword.fetch!(opts, :render),
      previous_values: Keyword.get(opts, :values, []),
      interval: Keyword.get(opts, :interval, 10_000)
    }

    {:ok, state, {:continue, :fetch}}
  end

  def handle_info(:fetch, state), do: handle_fetch(state)

  def handle_continue(:fetch, state), do: handle_fetch(state)

  defp handle_fetch(state) do
    latest_values = state[:call].()

    {new_previous_values, updates} =
      diff(state[:previous_values], latest_values, state[:transform])

    if Enum.any?(updates) do
      state[:render].(updates) |> IO.puts()
    end

    new_state = %{state | previous_values: new_previous_values}

    Process.send_after(self(), :fetch, state[:interval])

    {:noreply, new_state}
  end

  # TODO: More specific error message
  # TODO: same error appears to be seen as "new"
  defp diff(previous, {:error, reason}, _transformer) do
    case previous do
      {:error, ^reason} ->
        {[{:error, reason}], []}

      _otherwise ->
        {[{:error, reason}], [{:lines, ["Error: #{reason}"]}]}
    end
  end

  defp diff([], {:ok, values}, transformer) do
    current = transformer.(values)

    {current, current}
  end

  defp diff({:error, _reason}, {:ok, values}, transformer) do
    current = transformer.(values)

    {current, current}
  end

  defp diff(previous, {:ok, values}, transformer) do
    current = transformer.(values)

    diff = MapSet.difference(MapSet.new(current), MapSet.new(previous))

    {current, Enum.into(diff, [])}
  end
end
