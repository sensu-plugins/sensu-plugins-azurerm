#! /usr/bin/env ruby
#
# metric-azurerm-virtual-network-gateway-usage
#
# DESCRIPTION:
#   This plugin exposes the Virtual Network Gateway Ingress & Egress values as Metric's
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
#   ./metric-azurerm-virtual-network-gateway-usage.rb -r "resourcegroup" -n "gatewayname"
#
#   ./metric-azurerm-virtual-network-gateway-usage.rb
#                             -t "00000000-0000-0000-0000-000000000000"
#                             -c "00000000-0000-0000-0000-000000000000"
#                             -S "00000000-0000-0000-0000-000000000000"
#                             -s "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345678901234"
#                             -r "resourcegroup" -n "gatewayname"
#
#   ./metric-azurerm-virtual-network-gateway-usage.rb
#                             --tenant "00000000-0000-0000-0000-000000000000"
#                             --client "00000000-0000-0000-0000-000000000000"
#                             --clientSecret "00000000-0000-0000-0000-000000000000"
#                             --subscription "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345678901234"
#                             --resource_group_name "resourcegroup"
#                             --name "gatewayname"
#                             --customScheme "foo"
#
# NOTES:
#
# LICENSE:
#   Tom Harvey
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'azure_mgmt_network'
require 'sensu-plugin/metric/cli'
require 'sensu-plugins-azurerm'

class MetricAzureRMVirtualNetworkGatewayUsage < Sensu::Plugin::Metric::CLI::Statsd
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

  option :custom_scheme,
         description: 'Metric naming scheme, text to prepend to .$parent.$child',
         long: '--customScheme SCHEME',
         default: 'azurerm.virtualnetworkgateway'

  def run
    tenant_id = config[:tenant_id]
    client_id = config[:client_id]
    client_secret = config[:client_secret]
    subscription_id = config[:subscription_id]

    resource_group_name = config[:resource_group_name]
    name = config[:name]

    network_client = NetworkUsage.new.build_virtual_network_gateways_client(tenant_id, client_id, client_secret, subscription_id)
    result = network_client.get(resource_group_name, name)

    inbound = result.ingress_bytes_transferred
    outbound = result.egress_bytes_transferred

    timestamp = Time.now.utc.to_i
    scheme = config[:custom_scheme]
    name = [scheme, resource_group_name, name].join('.').tr(' ', '_').tr('{}', '').tr('[]', '')
    inbound_name = [name, 'inbound'].join('.')
    outbound_name = [name, 'outbound'].join('.')

    output inbound_name, inbound, timestamp
    output outbound_name, outbound, timestamp
    ok
  rescue StandardError => e
    puts "Error: exception: #{e}"
    critical
  end
end
