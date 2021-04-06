defmodule Mix.Tasks.Bake do
  use Mix.Task

  @shortdoc "Bake CLI into executable"
  def run([]) do
    Mix.Shell.cmd("rm -fr _build", &IO.puts/1)
    Mix.Shell.cmd("MIX_ENV=prod mix release script", &IO.puts/1)
    Mix.Shell.cmd("mv _build/prod/rel/bakeware/script ./kconnectex", &IO.puts/1)
  end
end
