defmodule Mix.Tasks.Bake do
  use Mix.Task

  @shortdoc "Bake CLI into executable"
  def run(args) do
    unless Enum.member?(args, "--no-cache") do
      Mix.Shell.cmd("rm -fr _build", &IO.puts/1)
    end

    Mix.Shell.cmd("MIX_ENV=prod mix release script --overwrite", &IO.puts/1)
    Mix.Shell.cmd("cp _build/prod/rel/bakeware/script ./kconnectex", &IO.puts/1)
  end
end
