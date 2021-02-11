defmodule Kconnectex.Request do
  @enforce_keys [:client]
  defstruct [:client, :mfa, conditions: []]

  import Kconnectex.Util, only: [handle_response: 1]

  def new(client) do
    %__MODULE__{client: client}
  end

  def get(req, path) do
    %{req | mfa: {Tesla, :get, [path]}}
  end

  def post(req, path, body) do
    %{req | mfa: {Tesla, :post, [path, body]}}
  end

  def put(req, path, body) do
    %{req | mfa: {Tesla, :put, [path, body]}}
  end

  def delete(req, path) do
    %{req | mfa: {Tesla, :delete, [path]}}
  end

  def validate(req, condition, message) do
    %{req | conditions: [{condition, message} | req.conditions]}
  end

  def execute(req) do
    case validate(req.conditions) do
      [] ->
        make_request(req) |> handle_response()

      errors ->
        messages = Enum.map(errors, fn {:error, msg} -> msg end)
        {:error, messages}
    end
  end

  defp validate(conditions) do
    conditions
    |> Enum.map(fn {condition, message} ->
      if check(condition) do
        :ok
      else
        {:error, message}
      end
    end)
    |> Enum.filter(&(&1 != :ok))
  end

  defp check({:present, str}) do
    str |> String.trim() |> String.length() > 0
  end

  defp check({:match, value, value}), do: true
  defp check({:match, _, _}), do: false

  defp check({:in, value, collection}), do: Enum.member?(collection, value)

  defp make_request(%{client: client, mfa: {m, f, a}}) do
    apply(m, f, [client | a])
  end

  defp make_request(_) do
    {:error, "HTTP request not provided. Call one of Request.get, Request.post, etc."}
  end
end
