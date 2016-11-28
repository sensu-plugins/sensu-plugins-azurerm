#! /usr/bin/env ruby
#
# check-azurerm-virtual-network-gateway-failover-connected
#
# DESCRIPTION:
#   This plugin checks that at least one of the specified Virtual Network Gateways is connected.
#   Firing a Critical alert if both are not in the Connected state.
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
#   ./check-azurerm-virtual-network-gateway-failover-connected.rb
#                             -r "resourcegroup"
#                             -p "primary_name"
#                             -s "secondary_name"
#
#   ./check-azurerm-virtual-network-gateway-failover-connected.rb
#                             -t "00000000-0000-0000-0000-000000000000"
#                             -c "00000000-0000-0000-0000-000000000000"
#                             -S "00000000-0000-0000-0000-000000000000"
#                             -s "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345678901234"
#                             -r "resourcegroup"
#                             -p "primary_name"
#                             -s "secondary_name"
#
#   ./check-azurerm-virtual-network-gateway-failover-connected.rb
#                             -tenant "00000000-0000-0000-0000-000000000000"
#                             -client "00000000-0000-0000-0000-000000000000"
#                             -client_secret "00000000-0000-0000-0000-000000000000"
#                             -subscription_id "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345678901234"
#                             -resourceGroup "resourcegroup"
#                             -primary_name "gatewayname"
#                             -secondary_name "gatewayname"
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
    long: '--client_secret SECRET',
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

  option :primary_name,
    description: 'Azure Virtual Network Connection Gateway Primary Name',
    short: '-p NAME',
    long: '--primary_name NAME'

  option :secondary_name,
    description: 'Azure Virtual Network Connection Gateway Secondary Name',
    short: '-s NAME',
    long: '--secondary_name NAME'

  def run
    tenant_id = config[:tenant_id]
    client_id = config[:client_id]
    client_secret = config[:client_secret]
    subscription_id = config[:subscription_id]

    resource_group_name = config[:resource_group_name]

    primary_name = config[:primary_name]
    secondary_name = config[:secondary_name]

    usage = NetworkUsage.new

    network_client = usage.build_virtual_network_client(tenant_id, client_id, client_secret, subscription_id)

    primary_result = network_client.get(resource_group_name, primary_name)
    primary_connection_state = primary_result.connection_status
    primary_inbound = primary_result.ingress_bytes_transferred
    primary_outbound = primary_result.egress_bytes_transferred

    secondary_result = network_client.get(resource_group_name, secondary_name)
    secondary_connection_state = secondary_result.connection_status
    secondary_inbound = secondary_result.ingress_bytes_transferred
    secondary_outbound = secondary_result.egress_bytes_transferred
    message = "Primary: State is '#{primary_connection_state}'. Usage is #{primary_inbound} in / #{primary_outbound} out.\n"
    message += "Secondary: State is '#{secondary_connection_state}'. Usage is #{secondary_inbound} in / #{secondary_outbound} out."

    if primary_result.connection_status.casecmp('connected') == 0 ||
       secondary_result.connection_status.casecmp('connected') == 0
      ok message
    else
      critical message
    end

  rescue => e
    puts "Error: exception: #{e}"
    critical
  end

end
