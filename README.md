# kconnectex

Elixir API wrapper for the [Kafka Connect API](https://docs.confluent.io/platform/current/connect/references/restapi.html)

Currently under development.

## TODO

* https://docs.confluent.io/platform/current/connect/references/restapi.html#put--connectors-(string-name)-config
* Move integration tests to a file
* Add more integration tests (with FileStreamSource)

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
