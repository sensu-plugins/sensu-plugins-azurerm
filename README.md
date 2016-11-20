## Sensu-Plugins-AzureRM

[![Build Status](https://travis-ci.org/tombuildsstuff/sensu-plugins-azurerm.svg?branch=master)](https://travis-ci.org/tombuildsstuff/sensu-plugins-azurerm)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-azurerm.svg)](http://badge.fury.io/rb/sensu-plugins-azurerm)
[![Code Climate](https://codeclimate.com/github/tombuildsstuff/sensu-plugins-azurerm/badges/gpa.svg)](https://codeclimate.com/github/tombuildsstuff/sensu-plugins-azurerm)
[![Test Coverage](https://codeclimate.com/github/tombuildsstuff/sensu-plugins-azurerm/badges/coverage.svg)](https://codeclimate.com/github/tombuildsstuff/sensu-plugins-azurerm)
[![Dependency Status](https://gemnasium.com/tombuildsstuff/sensu-plugins-azurerm.svg)](https://gemnasium.com/tombuildsstuff/sensu-plugins-azurerm)

## Functionality

**check-azurerm-core-usage.rb**


## Files

* /bin/check-azurerm-core-usage.rb

## Usage

**check-azurerm-core-usage.rb**
```
./check-azurerm-core-usage.rb -l "westeurope" -w 80 -c 90

./check-azurerm-core-usage.rb -t "00000000-0000-0000-0000-000000000000"
                              -c "00000000-0000-0000-0000-000000000000"
                              -S "00000000-0000-0000-0000-000000000000"
                              -s "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345678901234"
                              -l "eastus2" -w 80 -c 90

./check-azurerm-core-usage.rb -tenant "00000000-0000-0000-0000-000000000000"
                              -client_id "00000000-0000-0000-0000-000000000000"
                              -client_secret "00000000-0000-0000-0000-000000000000"
                              -subscription_id "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345678901234"
                              -location "westeurope"
                              -warning_percentage 80
                              -critical_percentage 90
```

## Installation

[Installation and Setup](http://sensu-plugins.io/docs/installation_instructions.html)
