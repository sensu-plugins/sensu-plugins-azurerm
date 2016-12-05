#Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed at [Keep A Changelog](http://keepachangelog.com/)

## Unreleased
### Added
- Checks for
  - ServiceBus subscription
  - ServiceBus topic size

## 0.0.4 - 2016-12-04
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

## 0.0.3 - 2016-11-24
### Added
- Virtual Network Gateways:
  - Added functionality to check Failover connections
  - Made it possible to specify a custom Scheme for Metrics
- Service Bus:
  - Added a Metric to expose the the Message Count for a Service Bus Topic

## 0.0.2 - 2016-11-23
### Added
- Virtual Network Gateways:
  - Check to ensure a given Virtual Network Gateway is Connected
  - Metrics exposed for a given Virtual Network Gateway

## 0.0.1 - 2016-11-18
### Added
- initial release
