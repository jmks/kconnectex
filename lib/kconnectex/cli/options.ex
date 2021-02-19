defmodule Kconnectex.CLI.Options do
  defstruct [
    :url,
    help?: false,
    command: [],
    errors: []
  ]

  def parse(args) do
    {parsed, command, invalid} = OptionParser.parse(args, strict: [url: :string, help: :boolean])

    %__MODULE__{}
    |> set_help(Keyword.get(parsed, :help, false))
    |> with_command(command)
    |> set_url(Keyword.get(parsed, :url))
    |> add_errors(invalid)
  end

  defp set_help(opts, help), do: %{opts | help?: help}

  defp set_url(%{help?: true} = opts, nil), do: opts

  defp set_url(opts, nil) do
    %{opts | errors: ["--url is required" | opts.errors]}
  end

  defp set_url(opts, url), do: %{opts | url: url}

  defp add_errors(opts, invalid) do
    messages =
      invalid
      |> Enum.map(&elem(&1, 0))
      |> Enum.map(fn opt -> "#{opt} is not valid" end)

    %{opts | errors: messages ++ opts.errors}
  end

  defp with_command(opts, []) do
    %{opts | help?: true}
  end

  defp with_command(opts, command) do
    %{opts | command: command}
  end
end
