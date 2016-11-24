module SensuPluginsAzureRM

  class ServiceBusUsage

    def buildServiceBusClient(tenant_id, client_id, secret, subscription_id)
      token_provider = MsRestAzure::ApplicationTokenProvider.new(tenant_id, client_id, secret)
      credentials = MsRest::TokenCredentials.new(token_provider)
      client = Azure::ARM::ServiceBus::ServiceBusManagementClient.new(credentials)
      client.subscription_id = subscription_id

      usageClient = Azure::ARM::ServiceBus::Subscriptions.new(client)
      usageClient
    end

  end
end