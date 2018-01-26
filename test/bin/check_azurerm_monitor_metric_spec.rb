require File.expand_path('../spec_helper', File.dirname(__FILE__))

ENV['ARM_TENANT_ID'] = 'armtenantid'
ENV['ARM_CLIENT_ID'] = 'armclientid'
ENV['ARM_CLIENT_SECRET'] = 'armclientsecret'

require File.expand_path('../../bin/check-azurerm-monitor-metric', File.dirname(__FILE__))

require 'webmock/rspec'

# rubocop:disable Metrics/BlockLength
describe 'check monitor metric script' do
  subject(:check_instance) { CheckAzurermMonitorMetric.new(script_args) }
  let(:script_args) do
    args = [
      '--resource', resource_id,
      '--metric', metric_name,
      '--critical', critical,
      '--warning', warning,
      '--critical-under', critical_under,
      '--warning-under', warning_under
    ]

    args += ['--filter', filter] if filter

    args
  end
  let(:resource_id) { 'resource' }
  let(:metric_name) { 'metric' }
  let(:critical) { '3.0' }
  let(:warning) { '100.0' }

  let(:critical_under) { '-100.0' }
  let(:warning_under) { '-100.0' }

  let(:expected_url) do
    url = "https://management.azure.com/#{resource_id}/providers/microsoft.insights/metrics?" \
      'api-version=2017-05-01-preview&' \
      "metric=#{metric_name}&" \
      "timespan=#{timespan}&" \
      "aggregation=#{aggregation}"

    url += "&$filter=#{filter}" if filter

    url
  end
  let(:timespan) do
    start_date = Time.now - 600
    end_date = Time.now

    "#{start_date.iso8601}/#{end_date.iso8601}"
  end

  let(:aggregation) { 'average' }
  let(:filter) { nil }

  let(:mock_az_provider) { double }

  let(:metric_resp) do
    {
      cost: 0.0,
      interval: '0:01:00',
      timespan: '2018-01-26T16:56:00Z/2018-01-26T17:56:00Z',
      value: value_list
    }
  end

  let(:value_list) { [value_obj] }

  let(:value_obj) do
    {
      id: '/subscriptions/576b7196-d42b-4b63-b696-af3ff33269a7/resourceGroups/test-group-1/providers/Microsoft.Network/virtualNetworkGateways/test-gateway/providers/Microsoft.Insights/metrics/TunnelAverageBandwidth',
      name: {
        localizedValue: 'Tunnel Bandwidth',
        value: 'TunnelAverageBandwidth'
      },
      resourceGroup: 'test-group-1',
      timeseries: [
        {
          data: [
            {
              average: value1,
              timeStamp: '2018-01-26T16:56:00+00:00'
            },
            {
              average: value2,
              timeStamp: '2018-01-26T16:56:00+00:00'
            },
            {
              average: value3,
              timeStamp: '2018-01-26T16:57:00+00:00'
            }
          ]
        }
      ]
    }
  end

  let(:value1) { '1.2' }
  let(:value2) { '2.2' }
  let(:value3) { '2.5' }

  before(:each) do
    mock_result_methods(check_instance)
    allow(MsRestAzure::ApplicationTokenProvider).to receive(:new).and_return(mock_az_provider)
    allow(mock_az_provider).to receive(:get_authentication_header).and_return('TOKEN')
    stub_request(:get, expected_url).to_return(body: JSON.dump(metric_resp))
  end

  context 'When metric not over thresholds' do
    it 'Returns ok' do
      check_instance.run

      expect(check_instance).to have_received(:ok)
    end

    it 'Retrieves the metric to compare' do
      check_instance.run

      expect(WebMock).to(have_requested(:get, expected_url).with do |req|
        expect(req.headers['Authorization']).to eq('TOKEN')
      end)
    end
  end

  context 'When last metric value is null' do
    let(:value2) { '2.0' }
    let(:value3) { nil }
    let(:critical) { '3.0' }
    it 'Uses the last entry with a value' do
      check_instance.run

      expect(check_instance).to have_received(:ok)
    end
  end

  context 'When no metric has a value' do
    let(:value1) { nil }
    let(:value2) { nil }
    let(:value3) { nil }
    it 'Returns an known response' do
      check_instance.run

      expect(check_instance).to have_received(:unknown)
    end
  end

  context 'When response has multiple entries in the value field' do
    let(:value_list) { [value_obj2, value_obj] }
    let(:value_obj2) do
      {
        id: '/subscriptions/576b7196-d42b-4b63-b696-af3ff33269a7/resourceGroups/test-group-1/providers/Microsoft.Network/virtualNetworkGateways/test-gateway/providers/Microsoft.Insights/metrics/TunnelAverageBandwidth',
        name: {
          localizedValue: 'Tunnel Bandwidth',
          value: 'TunnelAverageBandwidth'
        },
        resourceGroup: 'test-group-1',
        timeseries: [
          {
            data: [
              {
                average: '4.0',
                timeStamp: '2018-01-26T16:56:00+00:00'
              }
            ]
          }
        ]
      }
    end

    it 'Checks all values returned' do
      check_instance.run

      expect(check_instance).to have_received(:critical)
    end
  end

  context 'When response has no timeseries' do
    let(:value_obj) do
      {
        id: '/subscriptions/576b7196-d42b-4b63-b696-af3ff33269a7/resourceGroups/test-group-1/providers/Microsoft.Network/virtualNetworkGateways/test-gateway/providers/Microsoft.Insights/metrics/TunnelAverageBandwidth',
        name: {
          localizedValue: 'Tunnel Bandwidth',
          value: 'TunnelAverageBandwidth'
        },
        resourceGroup: 'test-group-1',
        timeseries: []
      }
    end

    it 'Returns an known response' do
      check_instance.run

      expect(check_instance).to have_received(:unknown)
    end
  end

  context 'When response has multiple time series' do
    let(:value_obj) do
      {
        id: '/subscriptions/576b7196-d42b-4b63-b696-af3ff33269a7/resourceGroups/test-group-1/providers/Microsoft.Network/virtualNetworkGateways/test-gateway/providers/Microsoft.Insights/metrics/TunnelAverageBandwidth',
        name: {
          localizedValue: 'Tunnel Bandwidth',
          value: 'TunnelAverageBandwidth'
        },
        resourceGroup: 'test-group-1',
        timeseries: [
          {
            data: [
              {
                average: '4.0',
                timeStamp: '2018-01-26T16:56:00+00:00'
              }
            ]
          },
          {
            data: [
              {
                average: '1.0',
                timeStamp: '2018-01-26T16:56:00+00:00'
              }
            ]
          }
        ]
      }
    end

    it 'Checks the last value in each time series' do
      check_instance.run

      expect(check_instance).to have_received(:critical)
    end
  end

  context 'When response has no data entry' do
    let(:value_obj) do
      {
        id: '/subscriptions/576b7196-d42b-4b63-b696-af3ff33269a7/resourceGroups/test-group-1/providers/Microsoft.Network/virtualNetworkGateways/test-gateway/providers/Microsoft.Insights/metrics/TunnelAverageBandwidth',
        name: {
          localizedValue: 'Tunnel Bandwidth',
          value: 'TunnelAverageBandwidth'
        },
        resourceGroup: 'test-group-1',
        timeseries: [
          {
            data: []
          }
        ]
      }
    end

    it 'Returns an unknown response' do
      check_instance.run

      expect(check_instance).to have_received(:unknown)
    end
  end

  context 'When no tenant, client, secret, and subscription given' do
    it 'Uses the values from the env' do
      check_instance.run

      expect(MsRestAzure::ApplicationTokenProvider).to have_received(:new).with(
        'armtenantid',
        'armclientid',
        'armclientsecret'
      )
    end
  end

  context 'When tenant, client, secret, and subscription given' do
    let(:script_args) do
      [
        '--resource', resource_id,
        '--metric', metric_name,
        '--critical', critical,
        '--tenant', tenant,
        '--client', clientId,
        '--clientSecret', clientSecret
      ]
    end

    let(:tenant) { 'tenant' }
    let(:clientId) { 'clientId' }
    let(:clientSecret) { 'clientSecret' }

    it 'uses the values supplied instead of the env' do
      check_instance.run

      expect(MsRestAzure::ApplicationTokenProvider).to have_received(:new).with(
        tenant,
        clientId,
        clientSecret
      )
    end
  end

  context 'When no thresholds given' do
    let(:script_args) do
      [
        '--resource', resource_id,
        '--metric', metric_name
      ]
    end

    it 'Returns an error' do
      check_instance.run

      expect(check_instance).to have_received(:critical)
    end
  end

  context 'When metric over thresholds given' do
    context 'And the metric exceeds the warning' do
      let(:value3) { '4.0' }
      let(:warning) { '3.0' }
      let(:critical) { '5.0' }

      it 'Returns warning' do
        check_instance.run

        expect(check_instance).to have_received(:warning)
      end
    end

    context 'And the metric exceeds the critical' do
      let(:value3) { '4.0' }
      let(:warning) { '3.0' }
      let(:critical) { '3.5' }
      it 'Returns a critical' do
        check_instance.run

        expect(check_instance).to have_received(:critical)
      end
    end
  end

  context 'When metric under thresholds given' do
    context 'And the metric lower the warning' do
      let(:value3) { '2.0' }
      let(:warning_under) { '3.0' }
      let(:critical_under) { '1.0' }

      it 'Returns warning' do
        check_instance.run

        expect(check_instance).to have_received(:warning)
      end
    end

    context 'And the metric lower the critical' do
      let(:value3) { '2.0' }
      let(:warning_under) { '3.0' }
      let(:critical_under) { '4.0' }

      it 'Returns a critical' do
        check_instance.run

        expect(check_instance).to have_received(:critical)
      end
    end
  end

  context 'When subscription, resource type, namespace, and group given' do
    let(:script_args) do
      [
        '--resource', resource_name,
        '--subscription', subscription,
        '--resource-type', resource_type,
        '--resource-namespace', resource_namespace,
        '--resource-group', resource_group,
        '--metric', metric_name,
        '--critical', critical
      ]
    end

    let(:resource_name) { 'res' }
    let(:resource_type) { 'type' }
    let(:resource_namespace) { 'Name.Space' }
    let(:resource_group) { 'group' }
    let(:resource_parent) { '' }
    let(:subscription) { 'sub' }

    let(:resource_id) do
      "subscriptions/#{subscription}/resourceGroups/#{resource_group}/" \
        "providers/#{resource_namespace}/#{resource_type}/#{resource_name}"
    end

    it 'Builds the Azure URL based on the components' do
      check_instance.run

      expect(WebMock).to have_requested(:get, expected_url)
    end

    context 'And parent given' do
      let(:script_args) do
        [
          '--resource', resource_name,
          '--subscription', subscription,
          '--resource-type', resource_type,
          '--resource-namespace', resource_namespace,
          '--resource-group', resource_group,
          '--resource-parent', resource_parent,
          '--metric', metric_name,
          '--critical', critical
        ]
      end

      let(:resource_parent) { 'parent' }

      let(:resource_id) do
        "subscriptions/#{subscription}/resourceGroups/#{resource_group}/" \
          "providers/#{resource_namespace}/#{resource_parent}/#{resource_type}/#{resource_name}"
      end

      it 'Builds the Azure URL with the parent' do
        check_instance.run

        expect(WebMock).to have_requested(:get, expected_url)
      end
    end

    context 'With data missing' do
      before do
        # this is needed since the call to unknown that would normally stop execution is mocked out.
        # Therefore, it still makes the URL call, so make sure it returns a correct value always.
        stub_request(:get, /.*management.azure.com.*/).to_return(body: JSON.dump(metric_resp))
      end

      context 'And namespace not given' do
        let(:resource_namespace) { '' }

        it 'Returns unknown' do
          check_instance.run

          expect(check_instance).to have_received(:unknown)
        end
      end

      context 'And type not given' do
        let(:resource_type) { '' }

        it 'Returns unknown' do
          check_instance.run

          expect(check_instance).to have_received(:unknown)
        end
      end

      context 'And group not given' do
        let(:resource_group) { '' }

        it 'Returns unknown' do
          check_instance.run

          expect(check_instance).to have_received(:unknown)
        end
      end
    end
  end

  context 'When filter provided' do
    let(:filter) { "APIName eq 'ChangeBlobLease'" }

    it 'Sets the filter query param' do
      check_instance.run

      expect(check_instance).to have_received(:ok)
    end
  end

  def mock_result_methods(instance)
    allow(instance).to receive(:unknown)
    allow(instance).to receive(:critical)
    allow(instance).to receive(:warning)
    allow(instance).to receive(:ok)
  end
end
