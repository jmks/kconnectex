defmodule Kconnectex.CLI.OptionsTest do
  use ExUnit.Case, async: true

  alias Kconnectex.CLI.Options

  test "--url is required" do
    opts = Options.parse([])

    assert "--url is required" in opts.errors
  end

  test "unexpected options are errors" do
    opts = Options.parse(["--unexpected"])

    assert "--unexpected is not valid" in opts.errors
  end

  test "no command defaults to help" do
    opts = Options.parse([])

    assert ["help"] == opts.command
  end

  test "a valid command" do
    opts = Options.parse(["--url", "example.com", "cluster", "info"])

    assert opts.url == "example.com"
    assert opts.command == ["cluster", "info"]
    assert opts.errors == []
  end
end