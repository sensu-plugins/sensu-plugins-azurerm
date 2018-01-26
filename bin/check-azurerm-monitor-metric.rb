require 'ms_rest_azure'

require 'sensu-plugin/check/cli'
require 'sensu-plugins-azurerm'

class CheckAzurermMonitorMetric < Sensu::Plugin::Check::CLI
  include SensuPluginsAzureRM

  AZURE_API_VER = "2017-05-01-preview"

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

  # option :subscription_id,
  #        description: 'ARM Subscription ID',
  #        short: '-S ID',
  #        long: '--subscription ID',
  #        default: ENV['ARM_SUBSCRIPTION_ID']

  # example id: /subscriptions/576b7196-d42b-4b63-b696-af3ff33269a7/resourceGroups/test-group-1/providers/Microsoft.Network/virtualNetworkGateways/test-gateway
  option :resource,
         description:  'The (full) id of the resource for the metric',
         short: '-r ID',
         long: '--resource ID',
         required: true

  option :metric,
         description:  'The name of the metric',
         short: '-m ID',
         long: '--metric ID',
         required: true

  option :dimensions,
         description:  'Comma delimited list of DimName=Value',
         short: '-d DIMENSIONS',
         long: '--dimensions DIMENSIONS',
         proc: proc { |d| parse_dimensions(d) },
         default: []

  option :aggregation,
         description:  'Aggregation.  This can be Average, Count, Maximum, Minimum, Total',
         short: '-a aggregation',
         long: '--aggregation aggregation',
         default: "average"

  option :warning_over,
         description: 'The warning threshold to check if the metric is forecasted to go over.',
         short: '-w N',
         long: '--warning WARN',
         proc: proc { |val| val.to_i }

  option :critical_over,
         description: 'The critical threshold to check if the metric is forecasted to go over.',
         short: '-c N',
         long: '--critical CRIT',
         proc: proc { |val| val.to_i }

  option :warning_under,
         description: 'The warning threshold to check if the metric is forecasted to go under.',
         short: '-W N',
         long: '--warning-under WARN',
         proc: proc { |val| val.to_i }

  option :critical_under,
         description: 'The critical threshold to check if the metric is forecasted to go under.',
         short: '-C N',
         long: '--critical-under CRIT',
         proc: proc { |val| val.to_i }


  def parse_dimensions(val)
    val.split(',')
      .collect { |dim_str| dim_str.split '=' }
      .collect { |dim_arr| { name: dim_arr[0], value: dim_arr[1] } }
  end

  def run
    if config[:critical_over] && last_metric_value > config[:critical_over].to_f
      critical "Metric #{config[:metric]} is #{last_metric_value}"
    elsif config[:warning_over] && last_metric_value > config[:warning_over].to_f
      warning "Metric #{config[:metric]} is #{last_metric_value}"
    elsif config[:critical_under] && last_metric_value < config[:critical_under].to_f
      critical "Metric #{config[:metric]} is #{last_metric_value}"
    elsif config[:warning_under] && last_metric_value < config[:warning_under].to_f
      warning "Metric #{config[:metric]} is #{last_metric_value}"
    else
      ok "Metric #{config[:metric]} is #{last_metric_value}"
    end
  end

  def last_metric_value
    @last_metric_value ||= get_last_metric_value
  end

  def get_last_metric_value
    metric_response[:value].last[:timeseries].last[:data].reverse_each { |val|
      if val[config[:aggregation].to_sym]
        return val[config[:aggregation].to_sym].to_f
      end
    }
  end

  def metric_response
    provider = MsRestAzure::ApplicationTokenProvider.new(
      config[:tenant_id],
      config[:client_id],
      config[:client_secret]
    )

    begin
      res = config[:resource].start_with?("/") ? config[:resource] : "/" + config[:resource]
      url = "https://management.azure.com#{res}/providers/microsoft.insights/metrics?" +
        "api-version=#{AZURE_API_VER}&" +
        "metric=#{config[:metric]}&" +
        "timespan=#{CGI.escape(timespan)}&" +
        "aggregation=#{config[:aggregation]}"

      uri = URI.parse(url)

      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        req = Net::HTTP::Get.new(uri)
        req["Authorization"] = provider.get_authentication_header
        req["Content-Type"] = "application/json"
        http.request(req)
      end
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET,
      EOFError, Net::HTTPBadResponse,
      Net::HTTPHeaderSyntaxError, Net::ProtocolError,
      Errno::ECONNREFUSED => e

      critical e
    end

    handle_response(res)

    JSON.parse(res.body, symbolize_names: true)
  end

  def timespan
    start_date = Time.now - 300 # 5 min
    end_date = Time.now
    "#{start_date.iso8601}/#{end_date.iso8601}"
  end

  def handle_response(res)
    case res
      when Net::HTTPSuccess then
        return
      else
        critical "Failed to get metric:\n#{res.body}"
    end

  end
end