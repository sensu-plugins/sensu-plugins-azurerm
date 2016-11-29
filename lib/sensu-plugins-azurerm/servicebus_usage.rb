require 'azure_mgmt_service_bus'

module SensuPluginsAzureRM
  class ServiceBusUsage
    def build_service_bus_client(tenant_id, client_id, secret, subscription_id)
      token_provider = MsRestAzure::ApplicationTokenProvider.new(tenant_id, client_id, secret)
      credentials = MsRest::TokenCredentials.new(token_provider)
      client = Azure::ARM::ServiceBus::ServiceBusManagementClient.new(credentials)
      client.subscription_id = subscription_id

      usage_client = Azure::ARM::ServiceBus::Subscriptions.new(client)
      usage_client
    end
  end
end
