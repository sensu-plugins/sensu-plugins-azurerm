# Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format located [here](https://github.com/sensu-plugins/community/blob/master/HOW_WE_CHANGELOG.md)

## [Unreleased]

### Changed
- Updated rake requirement from ~> 12.3 to ~> 13.0

## [4.0.1] - 2020-03-09
### Changed
- Fix for travis deploy of Bonsai asset build 

## [4.0.0] - 2020-03-09
### Added 
- Added Bonsai pieces
- Added Assets to README

### Breaking Changes
- Bump `sensu-plugin` dependency to `~> 4.0` you can read the changelog entries for [4.0](https://github.com/sensu-plugins/sensu-plugin/blob/master/CHANGELOG.md#400---2018-02-17)

### Changed 
- Updated ms_rest_azure to ['>= 0.6.2', '< 0.12.0']
- Updated bundler to '~> 2.1'
- Updated codeclimate-test-reporter to '~> 1.0'
- Updated mixlib-shellout to ['~> 2.2', '< 3.1.0']
- Updated rdoc to '~> 6.2'
- Updated rubocop to '~> 0.80.1'
- Updated serverspec to '~> 2.41.5'
- Updated yard to '~> 0.9.20'
- Remediated any new warnings from updated rubocop

## [3.1.0] - 2019-03-04
### Added
- check-azurerm-monitor-metric.rb: added `--aggregate_results aggregation_type TYPE` option that allows users to aggregate results returned from Azure DB query @MrMisa93

## [3.0.0] - 2018-09-15
### Security
- updated `yard` dependency to `~> 0.9.11` per: https://nvd.nist.gov/vuln/detail/CVE-2017-17042 which closes attacks against a yard server loading arbitrary files (@majormoses)

### Breaking Changes
- removed ruby support for `< 2.3` (@majormoses)

### Changed
- bumped minumum dependency of `sensu-plugin` to 2.5 (@majormoses)

## [2.1.0] - 2018-09-10
### Added
- check-azurerm-monitor-metric.rb: allows you to check against azure metric thresholds for a particular resource id or name (@thomaslitton)

### Changed
- updated `.gemspec` to reflect new url after transfer (@majormoses)

## [2.0.0] - 2017-12-11
### Security
- updated rubocop dependency to `~> 0.51.0` per: https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-8418. (@majormoses)

### Breaking Changes
- bumped dependency of `sensu-plugin` to 2.x you can read about it [here](https://github.com/sensu-plugins/sensu-plugin/blob/master/CHANGELOG.md#v200---2017-03-29) (@majormoses)

### Fixed
- updated missed refs in `.travis.yml` to old repo (@majormoses)


## [1.0.0] - 2017-12-10
### Changed
- changelog gudelines location (@majormoses)
- standard `.gitignore` (@majormoses)
- standard `Rakefile` (@majormoses)
- rubygems api key for sensu-plugins user (@majormoses)
- `.travis.yml` docker, notitications, test all versions on tag (@majormoses)


### Added
- version diff links (@majormoses)
- standard PR/issue templates (@majormoses)
- standard `.kitchen.yml` (@majormoses)
- ruby 2.4.1 testing (@majormoses)
- standard `test-kitchen`, `kitchen-docker`, `serverspec` testing skel (@majormoses)

## [0.0.5] - 2016-12-05
### Added
- Checks for
  - ServiceBus subscription
  - ServiceBus topic size

## [0.0.4] - 2016-12-04
### Added
- Checks for the following Quota's:
  - D Family Cores
  - DS Family Cores
  - DSv2 Family Cores
  - Dv2 Family Cores
  - F Family Cores
  - FS Family Cores
  - Load Balancers
  - Network Interfaces
  - Network Security Groups
  - Public IP Addresses
  - Route Tables
  - Static Public IP Addresses
  - Virtual Networks
### Changed
- Refactoring to match the linting guidelines.
### Fixed
- Documentation for Virtual Network Gateways

## [0.0.3] - 2016-11-24
### Added
- Virtual Network Gateways:
  - Added functionality to check Failover connections
  - Made it possible to specify a custom Scheme for Metrics
- Service Bus:
  - Added a Metric to expose the the Message Count for a Service Bus Topic

## [0.0.2] - 2016-11-23
### Added
- Virtual Network Gateways:
  - Check to ensure a given Virtual Network Gateway is Connected
  - Metrics exposed for a given Virtual Network Gateway

## [0.0.1] - 2016-11-18
### Added
- initial release

[Unreleased]: https://github.com/sensu-plugins/sensu-plugins-azurerm/compare/4.0.1..HEAD
[4.0.1]: https://github.com/sensu-plugins/sensu-plugins-azurerm/compare/4.0.0..4.0.1
[4.0.0]: https://github.com/sensu-plugins/sensu-plugins-azurerm/compare/3.1.0..4.0.0
[3.1.0]: https://github.com/sensu-plugins/sensu-plugins-azurerm/compare/3.0.0..3.1.0
[3.0.0]: https://github.com/sensu-plugins/sensu-plugins-azurerm/compare/2.1.0..3.0.0
[2.1.0]: https://github.com/sensu-plugins/sensu-plugins-azurerm/compare/2.0.0...2.1.0
[2.0.0]: https://github.com/sensu-plugins/sensu-plugins-azurerm/compare/1.0.0..2.0.0
[1.0.0]: https://github.com/sensu-plugins/sensu-plugins-azurerm/compare/0.0.5...1.0.0
[0.0.5]: https://github.com/sensu-plugins/sensu-plugins-azurerm/compare/0.0.4...0.0.5
[0.0.4]: https://github.com/sensu-plugins/sensu-plugins-azurerm/compare/0.0.3...0.0.4
[0.0.3]: https://github.com/sensu-plugins/sensu-plugins-azurerm/compare/0.0.2...0.0.3
[0.0.2]: https://github.com/sensu-plugins/sensu-plugins-azurerm/compare/0.0.1...0.0.2
[0.0.1]: https://github.com/sensu-plugins/sensu-plugins-azurerm/compare/f70cfb714fc13046362173033b063f0ccb11563a...0.0.1
