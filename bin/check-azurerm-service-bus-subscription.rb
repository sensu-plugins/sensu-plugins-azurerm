#! /usr/bin/env ruby
# frozen_string_literal: true

#
# check-azurerm-service-bus-subscription
#
# DESCRIPTION:
#   This plugin asserts that a given Service Bus Subscription exists
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: azure_mgmt_service_bus
#   gem: sensu-plugin
#
# USAGE:
#
#   ./check-azurerm-service-bus-subscription.rb
#                             --resourceGroup "resourcegroup"
#                             --namespace "namespace"
#                             --topic "topic"
#                             --subscriptionName "subscriptionName"
#
#   ./check-azurerm-service-bus-subscription.rb
#                             -t "00000000-0000-0000-0000-000000000000"
#                             -c "00000000-0000-0000-0000-000000000000"
#                             -S "00000000-0000-0000-0000-000000000000"
#                             -s "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345678901234"
#                             --resourceGroup "resourcegroup"
#                             --namespace "namespace"
#                             --topic "topic"
#                             --subscriptionName "subscriptionName"
#
# NOTES:
#
# LICENSE:
#   Andy Royle
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'azure_mgmt_service_bus'
require 'sensu-plugin/check/cli'
require 'sensu-plugins-azurerm'

class CheckAzureRMServiceBusSubscription < Sensu::Plugin::Check::CLI
  include SensuPluginsAzureRM

  option :tenant_id,
         description: 'ARM Tenant ID. Either set ENV[\'ARM_TENANT_ID\'] or provide it as an option',
         short: '-t ID',
         long: '--tenant ID',
         default: ENV['ARM_TENANT_ID']

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
         long: '--resourceGroup RESOURCEGROUP'

  option :namespace_name,
         description: 'Azure Service Bus Namespace Name',
         long: '--namespaceName NAMESPACE'

  option :topic_name,
         description: 'Azure Service Bus Topic Name',
         long: '--topicName TOPIC'

  option :subscription_name,
         description: 'Azure Service Bus Topic Name',
         long: '--subscriptionName TOPIC'

  def run
    tenant_id = config[:tenant_id]
    client_id = config[:client_id]
    client_secret = config[:client_secret]
    subscription_id = config[:subscription_id]

    resource_group_name = config[:resource_group_name]
    namespace_name = config[:namespace_name]
    topic_name = config[:topic_name]
    subscription_name = config[:subscription_name]

    service_bus_client = ServiceBusUsage.new.build_service_bus_subscription_client(tenant_id, client_id, client_secret, subscription_id)
    result = service_bus_client.get(resource_group_name, namespace_name, topic_name, subscription_name)

    if result.nil?
      critical "Subscription '#{config[:subscription_name]}' not found in topic '#{config[:topic_name]}'"
    else
      ok "Subscription '#{config[:subscription_name]}' was found in topic '#{config[:topic_name]}'"
    end
  rescue StandardError => e
    puts "Error: exception: #{e}"
    critical
  end
end
