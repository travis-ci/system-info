# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [2.0.3] - 2016-06-28
### Added
- Memcached version to default `commands.yml`

### Changed
- Testing against ruby 1.9.3 and 2.3.1

## [2.0.2] - 2015-11-25
### Changed
- Match release conditions on tags instead of `master`

### Fixed
- Also rescue `Errno::EINVAL` when checking TCP port availability

## [2.0.1] - 2015-11-18
### Changed
- Extracted prerelease suffix checking to `./bin/prerelease-suffix-check`
- Spec optimizations

## [2.0.0] - 2015-11-18
### Added
- RSpec specs with simplecov
- gemspec file

### Changed
- File layout for gemification
- Executable to be based on Thor

## [1.0.0] - 2015-11-17
### Added
- rubocop, vagrant, and bundler touchup for ease of deployment

[2.0.3]: https://github.com/travis-ci/system-info/compare/v2.0.2...v2.0.3
[2.0.2]: https://github.com/travis-ci/system-info/compare/v2.0.1...v2.0.2
[2.0.1]: https://github.com/travis-ci/system-info/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/travis-ci/system-info/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/travis-ci/system-info/compare/5508bb4...v1.0.0
