# Changelog

Breaking changes are prefixed with a "[BREAKING]" label.

## master (unreleased)


## 0.4.1 (2018-23-05)

### Changed

- Relax redis-rb dependency to support v4.0.0 or later [[#21](https://github.com/skroutz/rafka-rb/pull/21)]


## 0.4.0 (2018-09-04)

### Changed

- [BREAKING] Depend on redis-rb 3.3.2 or later [[#15](https://github.com/skroutz/rafka-rb/pull/15)]
- [BREAKING] `reconnect_attempts` option now defaults to `1` (ie. no reconnects) [[#15](https://github.com/skroutz/rafka-rb/pull/15)]




## 0.3.0 (2018-06-07)

### Added

- Consumers can now set their own librdkafka configuration [[#8](https://github.com/skroutz/rafka-rb/pull/8)]







## 0.2.5 (2018-05-15)

### Changed

- Depend on redis-rb 3.x


## 0.2.4 (2018-05-14)

### Changed

- Loosen redis-rb dependency requirement




## 0.2.3 (2018-05-07)

### Fixed

- `Consumer#consume` could yield a nil message to the block it received [[0ded948](https://github.com/skroutz/rafka-rb/commit/0ded94821b21d590a6cdf1314f85da56b48a9c40)]




## 0.2.2 (2018-05-04)

### Fixed

- SETNAME was incorrectly called more than once in batch mode [[3416d7](https://github.com/skroutz/rafka-rb/commit/3416d7bbd9f9e36b4e4d7f87f1e51ba2f559caf2)]




## 0.2.1 (2018-05-04)

### Fixed

- SETNAME was incorrectly called many times resulting in errors from Rafka [[bc9b081](https://github.com/skroutz/rafka-rb/commit/bc9b08145f5f1fd98d1badf92190038ab01d0a58))




## 0.2.0 (2018-05-04)

### Added

- Support for batch consuming [[#12](https://github.com/skroutz/rafka-rb/pull/12)]




## 0.1.0 (2018-04-24)

### Added

- Support for manual offset management [[#9](https://github.com/skroutz/rafka-rb/pull/9)]
