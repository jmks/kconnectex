# kconnectex

Elixir API wrapper for the [Kafka Connect API](https://docs.confluent.io/platform/current/connect/references/restapi.html)

Currently under development.

## CLI

This library includes an escript. It is inspired by [kaf](https://github.com/birdayz/kaf) for Kafka.

Build it and display the help:

```
$ mix escript.build
$ ./kconnectex --help
```

## TODO

### General
* Having a "client" and "request" seems redundant?
* Add more integration tests (with FileStreamSource)
* Validating a config where the connector name does not match config => 500 from Connect (bug?)
* docs for Connectors
* specs

### Connectors
* Support "expand" queries
  * Where are docs on these?

### Topics
* get
* reset

### CLI
* strictly output JSON?
* `completion` command to generate script for bash, zsh
* Run via docker
* github.com/bake-bake-bake/bakeware

#### config

* Find a way to write TOML without writing an encoder.
* add
* select
* remove

## Development

To run the unit tests:

```
$ mix test
```

To run the integration tests:

```
$ docker-compose up
$ mix test --include integration
```

## Installation

It's not in hex yet, but the adventurous can grab it from Github:

```elixir
def deps do
  [
    {:kconnectex, git: "https://github.com/jmks/kconnectex.git"}
  ]
end
```

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `kconnectex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:kconnectex, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/kconnectex](https://hexdocs.pm/kconnectex).
