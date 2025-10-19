defmodule Kconnectex.CLI.Table do
  defstruct [:column_widths, :headers, :rows]

  @column_spacer "   "

  def new(headers, rows \\ []) do
    column_widths =
      max_column_widths(
        List.duplicate(0, length(headers)),
        [headers | rows]
      )

    %__MODULE__{
      column_widths: column_widths,
      headers: headers,
      rows: rows
    }
  end

  def render(table) do
    render_rows(table, [table.headers | table.rows])
  end

  def render_rows(table, rows) do
    lines =
      rows
      |> Enum.map(fn
        {:lines, lines} ->
          Enum.join(lines, "\n")

        row ->
          [row, table.column_widths]
          |> Enum.zip()
          |> Enum.map(fn {value, column_width} ->
            if String.length(value) > column_width do
              String.slice(value, 0, column_width - 3) <> "..."
            else
              String.pad_trailing(value, column_width)
            end
          end)
          |> Enum.join(@column_spacer)
      end)
      |> Enum.map(&String.trim/1)

    Enum.join(lines, "\n")
  end

  defp max_column_widths(column_widths, rows) do
    rows
    |> Enum.reject(&match?({:lines, _}, &1))
    |> Enum.zip()
    |> Enum.map(fn col_tuple ->
      col_tuple
      |> Tuple.to_list()
      |> Enum.map(&value_length/1)
      |> Enum.max()
    end)
    |> Enum.zip(column_widths)
    |> Enum.map(&Tuple.to_list/1)
    |> Enum.map(&Enum.max/1)
  end

  defp value_length(value) do
    value
    |> to_string()
    |> String.length()
  end
end
