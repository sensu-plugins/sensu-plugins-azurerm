#! /usr/bin/env ruby
#
# check-azurerm-core-usage
#
# DESCRIPTION:
#   This plugin checks the number of CPU Cores allocated and available in a Region in Azure.
#   Warning and Critical Percentage thresholds may be set as needed.
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: azure_mgmt_compute
#   gem: sensu-plugin
#
# USAGE:
#   ./check-azurerm-core-usage.rb -l "westeurope" -w 80 -c 90
#
#   ./check-azurerm-core-usage.rb -t "00000000-0000-0000-0000-000000000000"
#                                 -c "00000000-0000-0000-0000-000000000000"
#                                 -S "00000000-0000-0000-0000-000000000000"
#                                 -s "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345678901234"
#                                 -l "eastus2" -w 80 -c 90
#
#   ./check-azurerm-core-usage.rb -tenant "00000000-0000-0000-0000-000000000000"
#                                 -client_id "00000000-0000-0000-0000-000000000000"
#                                 -client_secret "00000000-0000-0000-0000-000000000000"
#                                 -subscription_id "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345678901234"
#                                 -location "westeurope"
#                                 -warning_percentage 80
#                                 -critical_percentage 90
#
# NOTES:
#
# LICENSE:
#   Tom Harvey
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'sensu-plugins-azurerm'
require 'azure_mgmt_compute'

class AzureRMCoreUsage < Sensu::Plugin::Check::CLI
  include SensuPluginsAzureRM

  option :tenant_id,
       description: 'ARM Tenant ID. Either set ENV[\'ARM_TENANT_ID\'] or provide it as an option',
       short: '-t ID',
       long: '--tenant ID',
       default: ENV['ARM_TENANT_ID'] # TODO: can we pull these out from the Check too?

  option :client_id,
       description: 'ARM Client ID. Either set ENV[\'ARM_CLIENT_ID\'] or provide it as an option',
       short: '-c ID',
       long: '--client ID',
       default: ENV['ARM_CLIENT_ID']

  option :client_secret,
       description: 'ARM Client Secret. Either set ENV[\'ARM_CLIENT_SECRET\'] or provide it as an option',
       short: '-s SECRET',
       long: '--clientSecret SECRET',
       default: ENV['ARM_CLIENT_SECRET']

  option :subscription_id,
       description: 'ARM Subscription ID',
       short: '-S ID',
       long: '--subscription ID',
       default: ENV['ARM_SUBSCRIPTION_ID']

  option :location,
       description: 'Azure Location (e.g. westeurope/eastus2)',
       short: '-l LOCATION',
       long: '--location LOCATION'

  option :warning_percentage,
       description: 'Warning Percentage threshold for filter',
       short: '-w PERCENTAGE',
       long: '--warning PERCENTAGE'

  option :critical_percentage,
       description: 'Critical Percentage threshold for filter',
       short: '-c PERCENTAGE',
       long: '--critical PERCENTAGE'

  def run
    tenantId = config[:tenant_id]
    clientId = config[:client_id]
    clientSecret = config[:client_secret]
    subscriptionId = config[:subscription_id]
    location = config[:location]

    common = ComputeUsage.new()

    usageClient = common.buildUsageOperationClient(tenantId, clientId, clientSecret, subscriptionId)
    result = common.retrieveUsageStats(usageClient, location, 'cores')

    current_usage = result.current_value
    allowance = result.limit
    criticalPercentage = config[:critical_percentage].to_f
    warningPercentage = config[:warning_percentage].to_f

    message = "Current usage: #{current_usage} of #{allowance} Cores"

    percentage_used = (current_usage.to_f / allowance.to_f) * 100

    if percentage_used >= criticalPercentage
      critical message
    elsif percentage_used >= warningPercentage
      warning message
    else
      ok message
    end

  rescue => e
    puts "Error: exception: #{e}"
    critical
  end

end
