defmodule Kconnectex.UtilTest do
  use ExUnit.Case, async: true

  import Kconnectex.Util

  describe "handle_response" do
    test "returns :ok for success with no body" do
      assert handle_response({:ok, %{status: 200, body: ""}}) == :ok
      assert handle_response({:ok, %{status: 201, body: ""}}) == :ok
      assert handle_response({:ok, %{status: 202, body: ""}}) == :ok
    end

    test "returns body for success with a body" do
      body = %{"hello" => "world"}

      assert handle_response({:ok, %{status: 200, body: body}}) == body
    end

    test "returns not found error on 404" do
      assert handle_response({:ok, %{status: 404}}) == {:error, :not_found}
    end

    test "returns rebalancing error on 409 status" do
      assert handle_response({:ok, %{status: 409}}) == {:error, :rebalancing}
    end

    test "returns error with body for client errors" do
      body = %{"error" => "something"}

      assert handle_response({:ok, %{status: 400, body: body}}) == {:error, body}
    end

    test "returns error with body for server errors" do
      body = %{"error" => "something"}

      assert handle_response({:ok, %{status: 500, body: body}}) == {:error, body}
    end

    test "returns error tuples" do
      assert handle_response({:error, :oops}) == {:error, :oops}
    end
  end
end
