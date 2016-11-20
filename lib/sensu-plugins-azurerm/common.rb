module SensuPluginsAzureRM

  class Common

    def buildClient(tenant_id, client_id, secret, subscription_id)
      token_provider = MsRestAzure::ApplicationTokenProvider.new(tenant_id, client_id, secret)
      credentials = MsRest::TokenCredentials.new(token_provider)
      client = Azure::ARM::Compute::ComputeManagementClient.new(credentials)
      client.subscription_id = subscription_id

      usageClient = Azure::ARM::Compute::UsageOperations.new(client)
      usageClient
    end

    def retrieveUsageStats(client, location, name)
      usageStatistics = client.list(location)

      filteredStatistics = usageStatistics.select { |stat| stat.name.value == name }
      filteredStatistics[0]
    end

  end
end
