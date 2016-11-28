#! /usr/bin/env ruby
#
# metric-azurerm-service-bus-subscription-message-count
#
# DESCRIPTION:
#   This plugin exposes the Service Bus Subscription Message Counts as a Metric
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
#   ./metric-azurerm-service-bus-subscription-message-count.rb
#                             --resourceGroup "resourcegroup"
#                             --namespace "namespace"
#                             --topic "topic"
#                             --subscriptionName "subscriptionName"
#
#   ./metric-azurerm-service-bus-subscription-message-count.rb
#                             -t "00000000-0000-0000-0000-000000000000"
#                             -c "00000000-0000-0000-0000-000000000000"
#                             -S "00000000-0000-0000-0000-000000000000"
#                             -s "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345678901234"
#                             --resourceGroup "resourcegroup"
#                             --namespace "namespace"
#                             --topic "topic"
#                             --subscriptionName "subscriptionName"
#
#   ./metric-azurerm-service-bus-subscription-message-count.rb
#                             --tenant "00000000-0000-0000-0000-000000000000"
#                             --client "00000000-0000-0000-0000-000000000000"
#                             --clientSecret "00000000-0000-0000-0000-000000000000"
#                             --subscription_id "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345678901234"
#                             --resourceGroup "resourcegroup"
#                             --namespaceName "namespace"
#                             --topicName "topic"
#                             --subscriptionName "subscriptionName"
#                             --customScheme "foo"
#
# NOTES:
#
# LICENSE:
#   Tom Harvey
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/metric/cli'
require 'sensu-plugins-azurerm'
require 'azure_mgmt_service_bus'

class MetricAzureRMServiceBusSubscriptionMessageCount < Sensu::Plugin::Metric::CLI::Statsd
  include SensuPluginsAzureRM

  option :tenant_id,
    description: 'ARM Tenant ID. Either set ENV[\'ARM_TENANT_ID\'] or provide it as an option',
    short:       '-t ID',
    long:        '--tenant ID',
    default:     ENV['ARM_TENANT_ID'] # TODO: can we pull these out from the Check too?

  option :client_id,
    description: 'ARM Client ID. Either set ENV[\'ARM_CLIENT_ID\'] or provide it as an option',
    short:       '-c ID',
    long:        '--client ID',
    default:     ENV['ARM_CLIENT_ID']

  option :client_secret,
    description: 'ARM Client Secret. Either set ENV[\'ARM_CLIENT_SECRET\'] or provide it as an option',
    short:       '-s SECRET',
    long:        '--clientSecret SECRET',
    default:     ENV['ARM_CLIENT_SECRET']

  option :subscription_id,
    description: 'ARM Subscription ID',
    short:       '-S ID',
    long:        '--subscription ID',
    default:     ENV['ARM_SUBSCRIPTION_ID']

  option :resource_group_name,
    description: 'Azure Resource Group Name',
    long:        '--resourceGroup RESOURCEGROUP'

  option :namespace_name,
    description: 'Azure Service Bus Namespace Name',
    long:        '--namespaceName NAMESPACE'

  option :topic_name,
    description: 'Azure Service Bus Topic Name',
    long:        '--topicName TOPIC'

  option :subscription_name,
    description: 'Azure Service Bus Topic Name',
    long:        '--subscriptionName TOPIC'

  option :custom_scheme,
    description: 'Metric naming scheme, text to prepend to .$parent.$child',
    long:        '--customScheme SCHEME',
    default:     'azurerm.servicebus'

  def run
    tenant_id = config[:tenant_id]
    client_id = config[:client_id]
    client_secret = config[:client_secret]
    subscription_id = config[:subscription_id]

    resource_group_name = config[:resource_group_name]
    namespace_name = config[:namespace_name]
    topic_name = config[:topic_name]
    subscription_name = config[:subscription_name]

    usage = ServiceBusUsage.new

    service_bus_client = usage.build_service_bus_client(tenant_id, client_id, client_secret, subscription_id)
    result = service_bus_client.get(resource_group_name, namespace_name, topic_name, subscription_name)

    count = result.message_count

    timestamp = Time.now.utc.to_i
    scheme = config[:custom_scheme]
    name = [scheme, resource_group_name, namespace_name, topic_name, subscription_name].join('.').tr(' ', '_').tr('{}', '').tr('[]', '')
    metric_name = [name, 'message_count'].join('.')

    output metric_name, count, timestamp
    ok
  rescue => e
    puts "Error: exception: #{e}"
    critical
  end

end
