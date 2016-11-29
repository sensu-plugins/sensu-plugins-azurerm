#! /usr/bin/env ruby
#
# check-azurerm-virtual-network-gateway-connected
#
# DESCRIPTION:
#   This plugin checks the specified Virtual Network Gateway is connected.
#   Firing a Critical alert if this is not.
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: azure_mgmt_network
#   gem: sensu-plugin
#
# USAGE:
#   ./check-azurerm-virtual-network-gateway-connected.rb -r "resourcegroup" -n "gatewayname"
#
#   ./check-azurerm-virtual-network-gateway-connected.rb
#                             -t "00000000-0000-0000-0000-000000000000"
#                             -c "00000000-0000-0000-0000-000000000000"
#                             -S "00000000-0000-0000-0000-000000000000"
#                             -s "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345678901234"
#                             -r "resourcegroup" -n "gatewayname"
#
#   ./check-azurerm-virtual-network-gateway-connected.rb
#                             -tenant "00000000-0000-0000-0000-000000000000"
#                             -client "00000000-0000-0000-0000-000000000000"
#                             -clientSecret "00000000-0000-0000-0000-000000000000"
#                             -subscription "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345678901234"
#                             -resourceGroup "resourcegroup"
#                             -name "gatewayname"
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
require 'azure_mgmt_network'

class CheckAzureRMVirtualNetworkGatewayConnected < Sensu::Plugin::Check::CLI
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

  option :resource_group_name,
         description: 'Azure Resource Group Name',
         short: '-r RESOURCEGROUP',
         long: '--resourceGroup RESOURCEGROUP'

  option :name,
         description: 'Azure Virtual Network Connection Gateway Name',
         short: '-n NAME',
         long: '--name NAME'

  def run
    tenant_id = config[:tenant_id]
    client_id = config[:client_id]
    client_secret = config[:client_secret]
    subscription_id = config[:subscription_id]

    resource_group_name = config[:resource_group_name]
    name = config[:name]

    network_client = NetworkUsage.new.build_virtual_network_gateways_client(tenant_id, client_id, client_secret, subscription_id)
    result = network_client.get(resource_group_name, name)

    connection_state = result.connection_status
    inbound = result.ingress_bytes_transferred
    outbound = result.egress_bytes_transferred
    message = "State is '#{connection_state}'. Usage is #{inbound} in / #{outbound} out"
    if result.connection_status.casecmp('connected') == 0
      ok message
    else
      critical message
    end

  rescue => e
    puts "Error: exception: #{e}"
    critical
  end
end
