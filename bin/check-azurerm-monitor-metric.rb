require 'ms_rest_azure'

require 'sensu-plugin/check/cli'
require 'sensu-plugins-azurerm'

class CheckAzurermMonitorMetric < Sensu::Plugin::Check::CLI
  include SensuPluginsAzureRM

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

  option :subscription_id,
         description: 'ARM Subscription ID',
         short: '-S ID',
         long: '--subscription ID',
         default: ENV['ARM_SUBSCRIPTION_ID']

  option :resource_id,
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
    ok "Test"
  end
end