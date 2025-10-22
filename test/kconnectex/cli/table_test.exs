defmodule Kconnectex.CLI.TableTest do
  use ExUnit.Case, async: true

  alias Kconnectex.CLI.Table

  import RenderAssertions

  describe "print/2" do
    test "formats a table" do
      table = Table.new(["abc", "def"], [["1", "1001"]])

      out = Table.render(table)

      assert_rendered(out, """
      abc   def
      1     1001
      """)
    end

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
