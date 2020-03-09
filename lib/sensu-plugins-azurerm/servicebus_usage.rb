# frozen_string_literal: true

module SensuPluginsAzureRM
  class ServiceBusUsage
    def get_client(tenant_id, client_id, secret, subscription_id)
      token_provider = MsRestAzure::ApplicationTokenProvider.new(tenant_id, client_id, secret)
      credentials = MsRest::TokenCredentials.new(token_provider)
      client = Azure::ARM::ServiceBus::ServiceBusManagementClient.new(credentials)
      client.subscription_id = subscription_id
      client
    end

    def build_service_bus_subscription_client(tenant_id, client_id, secret, subscription_id)
      client = get_client(tenant_id, client_id, secret, subscription_id)
      usage_client = Azure::ARM::ServiceBus::Subscriptions.new(client)
      usage_client
    end

    def build_service_bus_topic_client(tenant_id, client_id, secret, subscription_id)
      client = get_client(tenant_id, client_id, secret, subscription_id)
      usage_client = Azure::ARM::ServiceBus::Topics.new(client)
      usage_client
    end
  end
end
