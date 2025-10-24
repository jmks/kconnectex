defmodule Kconnectex.CLI.TableTest do
  use ExUnit.Case, async: true

  alias Kconnectex.CLI.Table

  import RenderAssertions

  describe "render/2" do
    test "formats a table" do
      table = Table.new(["abc", "def"], [["1", "1001"]])

      out = Table.render(table)

      assert_rendered(out, """
      abc   def
      1     1001
      """)
    end

    test "formats a column by header metadata" do
      headers = [%{name: "City", min_width: 5}, "Team"]
      rows = [
        ["Tdot", "Blue Jays"],
        ["LA", "Dodgers"]
      ]
      table = Table.new(headers, rows)

      out = Table.render(table)

      assert_rendered(out, """
      City    Team
      Tdot    Blue Jays
      LA      Dodgers
      """)
    end
  end

  describe "render_rows/2" do
    test "formats subsequeant rows correctly" do
      table = Table.new(["wide-column", "narrow-column"], [["longer-than-column", "narrow"]])

      first = Table.render(table)
      second = Table.render_rows(table, [["narrow", "<- whitespace"]])

      assert_rendered(
        [first, second],
        """
        wide-column          narrow-column
        longer-than-column   narrow
        narrow               <- whitespace
        """
      )
    end

    test "truncates columns that are subsequently longer" do
      table = Table.new(["column"], [["a short column"]])

      first = Table.render(table)
      second = Table.render_rows(table, [["a much wider column"]])

      assert_rendered([first, second], """
      column
      a short column
      a much wide...
      """)
    end

    test "renders lines" do
      table = Table.new(["state"], [["OK"]])

      first = Table.render(table)

      second =
        Table.render_rows(table, [["ERROR"], {:lines, ["stacktrace line 1", "stacktrace line 2"]}])

      assert_rendered([first, second], """
      state
      OK
      ERROR
      stacktrace line 1
      stacktrace line 2
      """)
    end
  end
end
