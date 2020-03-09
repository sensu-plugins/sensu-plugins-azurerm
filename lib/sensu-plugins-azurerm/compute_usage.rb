# frozen_string_literal: true

module SensuPluginsAzureRM
  class ComputeUsage
    def build_usage_operation_client(tenant_id, client_id, secret, subscription_id)
      token_provider = MsRestAzure::ApplicationTokenProvider.new(tenant_id, client_id, secret)
      credentials = MsRest::TokenCredentials.new(token_provider)
      client = Azure::ARM::Compute::ComputeManagementClient.new(credentials)
      client.subscription_id = subscription_id

      usage_client = Azure::ARM::Compute::UsageOperations.new(client)
      usage_client
    end
  end
end
