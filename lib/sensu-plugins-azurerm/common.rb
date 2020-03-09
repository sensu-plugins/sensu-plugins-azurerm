# frozen_string_literal: true

module SensuPluginsAzureRM
  class Common
    def retrieve_usage_stats(client, location, name)
      usage_statistics = client.list(location)

      filtered_statistics = usage_statistics.select { |stat| stat.name.value == name }
      filtered_statistics[0]
    end
  end
end
