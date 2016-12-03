module SensuPluginsAzureRM
  class NetworkUsage
    def build_usage_client(tenant_id, client_id, secret, subscription_id)
      token_provider = MsRestAzure::ApplicationTokenProvider.new(tenant_id, client_id, secret)
      credentials = MsRest::TokenCredentials.new(token_provider)
      client = Azure::ARM::Network::NetworkManagementClient.new(credentials)
      client.subscription_id = subscription_id

      usage_client = Azure::ARM::Network::Usages.new(client)
      usage_client
    end

    def build_virtual_network_gateways_client(tenant_id, client_id, secret, subscription_id)
      token_provider = MsRestAzure::ApplicationTokenProvider.new(tenant_id, client_id, secret)
      credentials = MsRest::TokenCredentials.new(token_provider)
      client = Azure::ARM::Network::NetworkManagementClient.new(credentials)
      client.subscription_id = subscription_id

      usage_client = Azure::ARM::Network::VirtualNetworkGatewayConnections.new(client)
      usage_client
    end
  end
end
