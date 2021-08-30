# kconnectex

Elixir API wrapper for the [Kafka Connect API](https://docs.confluent.io/platform/current/connect/references/restapi.html)

Currently under development.

## How To Use

### Use as an Elixir library

```
client = Kconnectex.client "https://domain-and-port-to-kafka-connect-cluster"

{:ok, connectors} = Kconnectex.Connectors.list(client)
```

### As a CLI

This app includes escript configuration. The CLI is inspired by [kaf](https://github.com/birdayz/kaf) for Kafka.

Build it and display the help:

```
$ mix escript.build
$ ./kconnectex --help
```

### Run CLI via Docker

If you don't have Elixir on your system, you can run the CLI via Docker.

A docker image is provided and is hosted at [quay](https://www.quay.io).
A wrapper is also provided (`kconnectex_docker_wrapper`) to execute it in Docker.

```
$ cp ~/path/to/repo/kconnectex_docker_wrapper /somewhere/on/system/PATH/kconnectex
$ kconnectex cluster
{
  "commit": "6b2021cd52659cef",
  "kafka_cluster_id": "dK2QBCSU",
  "version": "2.6.1"
}
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
* restore `iex -S mix` functionality
* fix exit statuses
* Make errors uniform - error type?
* `completion` command to generate script for bash, zsh
* strictly output JSON (possible?)

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

### Release

You permission to push to the Docker repository (currently, just the author).

A script will release the CLI with a tag of the current version: `./release`

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
    {:kconnectex, "~> 0.2.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/kconnectex](https://hexdocs.pm/kconnectex).
