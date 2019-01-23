#! /usr/bin/env ruby
#
# check-azurerm-core-usage
#
# DESCRIPTION:
#   Checks an azure monitor metric against thresholds
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   Linux
#   Windows
#
# DEPENDENCIES:
#   gem: ms_rest_azure
#   gem: sensu-plugin
#
#

require 'ms_rest_azure'
require 'erb'

require 'sensu-plugin/check/cli'
require 'sensu-plugins-azurerm'

require 'time'
require 'net/http'

class CheckAzurermMonitorMetric < Sensu::Plugin::Check::CLI
  include SensuPluginsAzureRM

  AZURE_API_VER = '2017-05-01-preview'.freeze
  DATE_FORMAT = '%Y-%m-%dT%H:%M:%S'.freeze

  option :tenant_id,
         description: 'ARM Tenant ID. Either set ENV[\'ARM_TENANT_ID\'] or provide it as an option',
         short: '-t ID',
         long: '--tenant ID',
         default: ENV['ARM_TENANT_ID']

  option :client_id,
         description: 'ARM Client ID. Either set ENV[\'ARM_CLIENT_ID\'] or provide it as an option',
         short: '-i ID',
         long: '--client ID',
         default: ENV['ARM_CLIENT_ID']

  option :client_secret,
         description: 'ARM Client Secret. Either set ENV[\'ARM_CLIENT_SECRET\'] or provide it as an option',
         short: '-s SECRET',
         long: '--clientSecret SECRET',
         default: ENV['ARM_CLIENT_SECRET']

  option :use_assigned_identity,
         description: 'Use Managed Service Identity (MSI) for authentication.',
         short: '-l',
         long: '--use-assigned-identity',
         boolean: true,
         default: false

  option :local_auth_port,
         description: 'Port used to authenticate when using the local identity via Managed Service Identity (MSI)',
         short: '-o PORT',
         long: '--local-auth-port PORT',
         proc: proc(&:to_i),
         default: 50_342

  option :assigned_identity_resource,
         description: 'The resource to use when retrieving credentials.  Only used if the --use-assigned-identity option is used.',
         short: '-u RESOURCE_URL',
         long: '--assigned-identity-resource',
         default: 'https://management.azure.com/'

  option :subscription_id,
         description: 'ARM Subscription ID',
         short: '-S ID',
         long: '--subscription ID',
         default: ENV['ARM_SUBSCRIPTION_ID']

  option :resource_name,
         description:  'The name of the resource.  If given, the resource namespace/type/group along with subscription id are also required.',
         short: '-e NAME',
         long: '--resource-name NAME',
         default: ''

  option :resource_type,
         description: 'Resource Type.  If specified, the resource should contain the name and not the full id, and the ' \
                      'resource namespace/group and subscriptions are also required. Note:  This should not contain the ' \
                      'namespace.  Use --resource-namespace instead.',
         short: '-y NAME',
         long: '--resource-type NAME',
         default: ''

  option :resource_namespace,
         description: 'Resource Namespace.  If specified, the resource should contain the name and not the full id, and the resource namespace/group and subscriptions are also required.',
         short: '-n NAME',
         long: '--resource-namespace NAME',
         default: ''

  option :resource_group,
         description: 'Resource Group.  If specified, the resource should contain the name and not the full id, and the resource namespace/group and subscriptions are also required.',
         short: '-g NAME',
         long: '--resource-group NAME',
         default: ''

  option :resource_parent,
         description: 'Resource Parent.',
         short: '-p NAME',
         long: '--resource-parent NAME',
         default: ''

  # example id: /subscriptions/576b7196-d42b-4b63-b696-af3ff33269a7/resourceGroups/test-group-1/providers/Microsoft.Network/virtualNetworkGateways/test-gateway
  option :resource_id,
         description:  'The full id of the resource.  If given, the resource namespace/type/group along with subscription id are ignored.',
         short: '-r ID',
         long: '--resource-id ID',
         default: ''

  option :metric,
         description:  'The name of the metric',
         short: '-m ID',
         long: '--metric ID',
         required: true

  option :filter,
         description:  "The filter applied to the metric.  See Azure docs for the syntax.  Note: This can be used to segment the return by dimensions, so that the script checks each dimension separately. eg APIName eq '*'",
         short: '-f FILTER',
         long: '--filter FILTER'

  option :request_aggregation,
         description:  'Used as a parameter to the HTTP request sent to Azure.   This can be Average, Count, Maximum, Minimum, Total',
         short: '-a aggregation',
         long: '--aggregation aggregation',
         default: 'average'

  option :aggregate_results,
         description: 'Aggregate the result data points to compare against alert conditions.   This can be Average, Count, Maximum, Minimum, Total',
         long: '--aggregate_results aggregation_type'

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

  option :base_url,
         description: 'The Azure resource API URL.',
         short: '-b URL',
         long: '--base-url URL',
         default: 'https://management.azure.com',
         proc: proc { |val| val.chomp('/') }

  option :lookback_period,
         description:  'The amount of time (in seconds) from the current time to look back when retrieving the metric.  This should be long enough to capture the last value submitted.',
         short: '-k PERIOD',
         long: '--look-back-period PERIOD',
         default: 600, # 10 min.  This should generally be enough time to capture the last value, without wasting API credits
         proc: proc { |val| val.to_i }

  def run
    check_missing_resource_info

    if !config[:critical_over] && !config[:warning_over] && !config[:critical_under] && !config[:warning_under]
      unknown 'At least one threshold must be provided.'
    end

    if !config[:aggregate_results]
      if last_metric_values.empty?
        unknown "There are no metric values for #{config[:metric]} on resource #{config[:resource_id] || config[:resource_name]} with aggregation #{config[:aggregation]}"
      else
        critical_messages = []
        warning_messages = []

        last_metric_values.each do |metric_val|
          if config[:critical_over] && metric_val[:value] > config[:critical_over].to_f
            critical_messages << "Metric #{metric_val[:metric_name]} is #{metric_val[:value]}"
          elsif config[:warning_over] && metric_val[:value] > config[:warning_over].to_f
            warning_messages << "Metric #{metric_val[:metric_name]} is #{metric_val[:value]}"
          elsif config[:critical_under] && metric_val[:value] < config[:critical_under].to_f
            critical_messages << "Metric #{metric_val[:metric_name]} is #{metric_val[:value]}"
          elsif config[:warning_under] && metric_val[:value] < config[:warning_under].to_f
            warning_messages << "Metric #{metric_val[:metric_name]} is #{metric_val[:value]}"
          end
        end

        if !critical_messages.empty?
          critical critical_messages.join("\n")
        elsif !warning_messages.empty?
          warning warning_messages.join("\n")
        else
          ok 'Metric(s) are within thresholds'
        end
      end
    else
      verify_results_with_aggregation
    end
  end

  def check_missing_resource_info
    return_missing_resource if missing_resource_id? && missing_resource_name_info?
  end

  def missing_resource_id?
    config[:resource_id].to_s.empty?
  end

  def missing_resource_name_info?
    config[:resource_name].to_s.empty? ||
      config[:resource_type].to_s.empty? ||
      config[:resource_namespace].to_s.empty? ||
      config[:resource_group].to_s.empty? ||
      config[:subscription_id].to_s.empty?
  end

  def return_missing_resource
    unknown(
      "Either the resource id is required OR the resource name, resource group, resource namepsace, resource type and subscription id are required.\n"\
      "Resource id: #{config[:resource_id]}\n"\
      "Resource Info:\n"\
      "Name: #{config[:resource_name]}\n"\
      "Group: #{config[:resource_group]}\n"\
      "Namespace: #{config[:resource_namespace]}\n"\
      "Type: #{config[:resource_type]}\n"\
      "Subscription ID: #{config[:subscription_id]}"
    )
  end

  def last_metric_values
    @last_metric_values ||= find_last_metric_values
  end

  def find_last_metric_values
    values = []
    metric_response[:value].each do |metric_resp_value|
      name = metric_resp_value[:name] ? metric_resp_value[:name][:value] : ''

      next if metric_resp_value[:timeseries].empty?

      metric_resp_value[:timeseries].each do |ts|
        ts[:data].reverse_each do |metric_value|
          if metric_value[metric_value_key]
            values << {
              value: metric_value[metric_value_key].to_f,
              metric_name: name
            }

            break
          end
        end
      end
    end

    values
  end

  def metric_value_key
    config[:request_aggregation].to_sym
  end

  def metric_response
    auth_header = if config[:use_assigned_identity]
                    uri = URI.parse("http://localhost:#{config[:local_auth_port]}/oauth2/token?resource=#{config[:assigned_identity_resource]}")

                    res = Net::HTTP.start(uri.host, uri.port, use_ssl: false) do |http|
                      req = Net::HTTP::Get.new(uri)
                      req['Metadata'] = 'true'
                      http.request(req)
                    end

                    handle_response(res)

                    auth_resp = JSON.parse(res.body, symbolize_names: true)

                    "#{auth_resp[:token_type]} #{auth_resp[:access_token]}"
                  else
                    provider = MsRestAzure::ApplicationTokenProvider.new(
                      config[:tenant_id],
                      config[:client_id],
                      config[:client_secret]
                    )

                    provider.get_authentication_header
                  end

    begin
      url = "#{config[:base_url]}#{resource}/providers/microsoft.insights/metrics?" \
        "api-version=#{AZURE_API_VER}&" \
        "metric=#{config[:metric]}&" \
        "timespan=#{CGI.escape(timespan)}&" \
        "aggregation=#{config[:request_aggregation]}"

      url += "&$filter=#{CGI.escape(config[:filter])}" if config[:filter]

      uri = URI.parse(url)

      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        req = Net::HTTP::Get.new(uri)
        req['Authorization'] = auth_header
        req['Content-Type'] = 'application/json'
        http.request(req)
      end
    rescue Timeout::Error,
           Errno::EINVAL, Errno::ECONNRESET,
           EOFError, Net::HTTPBadResponse,
           Net::HTTPHeaderSyntaxError, Net::ProtocolError,
           Errno::ECONNREFUSED => e

      critical e
    end

    handle_response(res)

    JSON.parse(res.body, symbolize_names: true)
  end

  def resource
    @resource ||= build_resource
  end

  def build_resource
    if !config[:resource_id].to_s.empty?
      config[:resource_id].start_with?('/') ? config[:resource_id] : '/' + config[:resource_id]
    else
      "/subscriptions/#{config[:subscription_id]}/resourceGroups/#{config[:resource_group]}/" \
        "providers/#{resource_type}/#{config[:resource_name]}"
    end
  end

  def resource_type
    if config[:resource_parent].to_s.empty?
      "#{config[:resource_namespace]}/#{config[:resource_type]}"
    else
      "#{config[:resource_namespace]}/#{config[:resource_parent]}/#{config[:resource_type]}"
    end
  end

  def timespan
    start_date = Time.now.utc - config[:lookback_period]
    end_date = Time.now.utc
    "#{start_date.strftime(DATE_FORMAT)}/#{end_date.strftime(DATE_FORMAT)}"
  end

  def handle_response(res)
    critical "Failed to get metric:\n#{res.body}" if res.code.to_i >= 300
  end

  def verify_results_with_aggregation
    request_values = extract_request_values

    aggregated_value = aggregate_request_values(request_values, config[:aggregate_results])

    error_type = verify_result(aggregated_value)

    return_error_message(error_type, request_values[0][:name], aggregated_value)
  end

  def extract_request_values
    values = []
    metric_response[:value].each do |metric_resp_value|
      name = metric_resp_value[:name] ? metric_resp_value[:name][:value] : ''

      next if metric_resp_value[:timeseries].empty?

      metric_resp_value[:timeseries].each do |ts|
        ts[:data].each do |metric_value|
          if metric_value[metric_value_key]
            values << {
              value: metric_value[metric_value_key].to_f,
              name: name
            }
          end
        end
      end
    end
    values
  end

  def aggregate_request_values(request_values, aggregation_type)
    result_values = []

    request_values.each do |metric_val|
      result_values.push(metric_val[:value])
    end

    case aggregation_type
    when 'average'
      result_value = result_values.inject { |sum, el| sum + el }.to_f / result_values.size
    when 'maximum'
      result_value = result_values.max
    when 'minimum'
      result_value = result_values.min
    when 'total'
      result_value = result_values.inject(0) {|sum, x| sum + x }
    when 'count'
      result_value = result_values.size
    end
    result_value
  end

  def verify_result(aggregated_value)
    error_type = 'none'
    if config[:critical_over] && aggregated_value > config[:critical_over].to_f
      error_type = 'critical'
    elsif config[:warning_over] && aggregated_value > config[:warning_over].to_f
      error_type = 'warning'
    elsif config[:critical_under] && aggregated_value < config[:critical_under].to_f
      error_type = 'critical'
    elsif config[:warning_under] && aggregated_value < config[:warning_under].to_f
      error_type = 'warning'
    end
    error_type
  end

  def return_error_message(type, metric_name, aggregated_value)
    message = 'Metric #{metric_name} is #{aggregated_value}'
    case type
    when 'none'
      ok 'Metric(s) are within thresholds'
    when 'warning'
      warning message
    when 'critical'
      critical message
    end
  end
end
