# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Template

```
## [Unreleased] - YYYY-MM-DD
### Added
### Fixed
### Changed
### Removed
### Security
```

## [Unreleased] - YYYY-MM-DD

### Added

* (client) Add `Connectors.offsets` and `Connectors.reset_offsets/2`
* (cli) Add `connector restart` options `--include-tasks` and `--only-failed`
* (client) Add `includeTasks` and `onlyFailed` options to `Connectors.restart/3`

Both default to `false`.

* (client) Add `:expand` option to `Connectors.list/2`

Can be `:info`, `:status`, or both as `[:info, :status]`.

* (cli) Add `--expand` option to `connectors`

Can be a comma-separated list of values for `:expand` in `Connectors.list/2`.

* (cli) Add `--json` option to `plugin validate`

By default, now shows a table of configuration errors. The `--json` flag will
show the fulll JSON response.

### Fixed

* `plugins validate` was renamed `plugin validate` for consistency

### Changed
### Removed
### Security

## [0.3.0] - 2021-09-09

### Added

* Updated Elixir version to 1.12.2
