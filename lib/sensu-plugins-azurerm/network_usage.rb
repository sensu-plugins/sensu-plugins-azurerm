module SensuPluginsAzureRM

  class NetworkUsage

    def buildVirtualNetworkClient(tenant_id, client_id, secret, subscription_id)
      token_provider = MsRestAzure::ApplicationTokenProvider.new(tenant_id, client_id, secret)
      credentials = MsRest::TokenCredentials.new(token_provider)
      client = Azure::ARM::Network::NetworkManagementClient.new(credentials)
      client.subscription_id = subscription_id

      usageClient = Azure::ARM::Network::VirtualNetworkGatewayConnections.new(client)
      usageClient
    end

  end
end
