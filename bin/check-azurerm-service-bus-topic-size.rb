#! /usr/bin/env ruby
#
# check-azurerm-service-bus-topic-size
#
# DESCRIPTION:
#   This plugin checks a given Service Bus Topic percentage used with warning/critical thresholds
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
#   ./check-azurerm-service-bus-topic-size.rb
#                             --resourceGroup "resourcegroup"
#                             --namespace "namespace"
#                             --topic "topic"
#                             -w 60
#                             -c 80
#
#   ./check-azurerm-service-bus-topic-size.rb
#                             -t "00000000-0000-0000-0000-000000000000"
#                             -c "00000000-0000-0000-0000-000000000000"
#                             -S "00000000-0000-0000-0000-000000000000"
#                             -s "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345678901234"
#                             --resourceGroup "resourcegroup"
#                             --namespace "namespace"
#                             --topic "topic"
#                             -w 60
#                             -c 80
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

class CheckAzureRMServiceBusTopicSize < Sensu::Plugin::Check::CLI
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

  option :warning_percentage,
         description: 'Warning Percentage threshold for filter',
         short: '-w PERCENTAGE',
         long: '--warning PERCENTAGE',
         proc: proc { |l| l.to_f }

  option :critical_percentage,
         description: 'Critical Percentage threshold for filter',
         short: '-c PERCENTAGE',
         long: '--critical PERCENTAGE',
         proc: proc { |l| l.to_f }

  def run
    tenant_id = config[:tenant_id]
    client_id = config[:client_id]
    client_secret = config[:client_secret]
    subscription_id = config[:subscription_id]

    resource_group_name = config[:resource_group_name]
    namespace_name = config[:namespace_name]
    topic_name = config[:topic_name]

    warning_percentage = config[:warning_percentage]
    critical_percentage = config[:critical_percentage]

    service_bus_client = ServiceBusUsage.new.build_service_bus_topic_client(tenant_id, client_id, client_secret, subscription_id)
    result = service_bus_client.get(resource_group_name, namespace_name, topic_name)

    max_size_in_bytes = result.max_size_in_megabytes * 1024 * 1024
    current_size = result.size_in_bytes
    percentage_used = (current_size.to_f / max_size_in_bytes.to_f) * 100

    message = "Current size of topic '#{topic_name}' is #{percentage_used}"

    if percentage_used >= critical_percentage
      critical message
    elsif percentage_used >= warning_percentage
      warning message
    else
      ok message
    end

  rescue => e
    puts "Error: exception: #{e}"
    critical
  end
end
