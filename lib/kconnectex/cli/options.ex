defmodule Kconnectex.CLI.Options do
  defstruct [
    :url,
    command: [],
    errors: []
  ]

  def parse(args) do
    {parsed, command, invalid} = OptionParser.parse(args, strict: [url: :string])

    %__MODULE__{}
    |> with_command(command)
    |> add_url(parsed)
    |> add_errors(invalid)
  end

  defp add_url(opts, url: url), do: %{opts | url: url}

  defp add_url(opts, _) do
    if opts.command == ["help"] or List.last(opts.command) == "help" do
      opts
    else
      %{opts | errors: ["--url is required" | opts.errors]}
    end
  end

  defp add_errors(opts, invalid) do
    messages =
      invalid
      |> Enum.map(&elem(&1, 0))
      |> Enum.map(fn opt -> "#{opt} is not valid" end)

    %{opts | errors: messages ++ opts.errors}
  end

  defp with_command(opts, []) do
    %{opts | command: ["help"]}
  end

  defp with_command(opts, command) do
    %{opts | command: command}
  end
end
