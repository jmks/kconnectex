defmodule Kconnectex.MixProject do
  use Mix.Project

  def project do
    [
      app: :kconnectex,
      version: "0.3.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Kconnectex.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}

      {:tesla, "~> 1.15.0"},
      {:hackney, "~> 1.21.0"},
      {:jason, ">= 1.0.0"},
      # https://github.com/deadtrickster/ssl_verify_fun.erl/pull/27
      {:ssl_verify_fun, ">= 0.0.0", manager: :rebar3, override: true},
      {:table_rex, "~> 4.1"}
    ]
  end

  defp escript do
    [
      main_module: Kconnectex.CLI
    ]
  end
end
