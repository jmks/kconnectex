# kconnectex

Elixir API wrapper for the [Kafka Connect API](https://docs.confluent.io/platform/current/connect/references/restapi.html)

Currently under development.

## TODO

### Connectors
* Support "expand" queries
  * Where are docs on these?

### Topics
* get
* reset

### General
* Having a "client" and request seems redundant??
* Add more integration tests (with FileStreamSource)
* Validating a config where the connector name does not match config => 500 from Connect (bug?)

## Development

To run the (unit) tests:

```
$ mix test
```

To run the integration tests:

```
$ docker-compose up
$ mix test --include integration
```

## Installation

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
