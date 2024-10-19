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

* (client) `Connectors.restart/3` adds options `includeTasks` and `onlyFailed`

Both default to `false`.

* (client) `Connectors.list/2` adds option `expand`

Can be `:info`, `:status`, or both as `[:info, :status]`.

* (cli) `connectors` adds `--expand` option

Can be a comma-separated list of values for `:expand` in `Connectors.list/2`.

* (cli) `plugin validate` adds `--errors-only` option

This will only configs that have an error present.

### Fixed

* `plugins validate` was renamed `plugin validate` for consistency

### Changed
### Removed
### Security

## [0.3.0] - 2021-09-09

### Added

* Updated Elixir version to 1.12.2
