defmodule Kconnectex.UtilTest do
  use ExUnit.Case, async: true

  import Kconnectex.Util

  describe "handle_response" do
    test "returns :ok for success with no body" do
      assert handle_response({:ok, %{status: 200, body: ""}}) == :ok
      assert handle_response({:ok, %{status: 202, body: ""}}) == :ok
    end

    test "returns deserialized JSON for success with a body" do
      assert handle_response({:ok, %{status: 200, body: %{"hello" => "world"}}}) == %{"hello" => "world"}
    end

    test "returns rebalancing error on 409 status" do
      assert handle_response({:ok, %{status: 409}}) == {:error, :rebalancing}
    end

    test "returns error tuples" do
      assert handle_response({:error, :oops}) == {:error, :oops}
    end
  end
end
