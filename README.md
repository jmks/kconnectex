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

### Connector Plugins
* get
* validate config

### General
* Move integration tests to a file
* URL sanitize URL params
* Add more integration tests (with FileStreamSource)
* Better API for Clients?

Would be nice to not have to pass "connector" to every function in Connectors?
```
client =
  base_url
  |> Kconnectex.Client.new
  |> Kconnectex.Client.adapter(FakeTasksAdapter)
  |> Kconnectex.Client.connector("filestream")


client
|> Kconnectex.Connectors.status
|> Access.get("tasks")
|> Enum.filter(fn %{"state" => state} -> state != "RUNNING")
|> Enum.map(fn %{"id" => id} -> Kconnectex.Connectors.restart(client, id))
```

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
