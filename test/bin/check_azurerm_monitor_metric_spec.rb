require File.expand_path('../spec_helper', File.dirname(__FILE__))


ENV["ARM_TENANT_ID"] = "armtenantid"
ENV["ARM_CLIENT_ID"] = "armclientid"
ENV["ARM_CLIENT_SECRET"] = "armclientsecret"

require File.expand_path('../../bin/check-azurerm-monitor-metric', File.dirname(__FILE__))

require 'webmock/rspec'

describe "check monitor metric script" do
  subject(:check_instance) { CheckAzurermMonitorMetric.new(script_args) }
  let(:script_args) { [
    "--resource", resource_id,
    "--metric", metric_name,
    "--critical", critical,
    "--warning", warning,
    "--critical-under", critical_under,
    "--warning-under", warning_under
  ] }
  let(:resource_id) { "resource" }
  let(:metric_name) { "metric" }
  let(:critical) { "3.0" }
  let(:warning) { "100.0" }

  let(:critical_under) { "-100.0" }
  let(:warning_under) { "-100.0" }

  let(:expected_url) {
    "https://management.azure.com/#{resource_id}/providers/microsoft.insights/metrics?" +
      "api-version=2017-05-01-preview&" +
      "metric=#{metric_name}&" +
      "timespan=#{timespan}&" +
      "aggregation=#{aggregation}"
  }
  let(:timespan) {
    start_date = Time.now - 300
    end_date = Time.now

    "#{start_date.iso8601}/#{end_date.iso8601}"
  }

  let(:aggregation) { "average" }

  let(:mock_az_provider) { double }

  let(:metric_resp) {
    {
      cost: 0.0,
      interval: "0:01:00",
      timespan: "2018-01-26T16:56:00Z/2018-01-26T17:56:00Z",
      value: value_list
    }
  }

  let(:value_list) { [value_obj] }

  let(:value_obj) {
    {
      id: "/subscriptions/576b7196-d42b-4b63-b696-af3ff33269a7/resourceGroups/test-group-1/providers/Microsoft.Network/virtualNetworkGateways/test-gateway/providers/Microsoft.Insights/metrics/TunnelAverageBandwidth",
      name: {
        localizedValue: "Tunnel Bandwidth",
        value: "TunnelAverageBandwidth"
      },
      resourceGroup: "test-group-1",
      timeseries: [
        {
          data: [
            {
              average: value1,
              timeStamp: "2018-01-26T16:56:00+00:00"
            },
            {
              average: value2,
              timeStamp: "2018-01-26T16:56:00+00:00"
            },
            {
              average: value3,
              timeStamp: "2018-01-26T16:57:00+00:00"
            }
          ]
        }
      ]
    }
  }

  let(:value1) { "1.2" }
  let(:value2) { "2.2" }
  let(:value3) { "2.5" }

  before(:each) do
    mock_result_methods(check_instance)
    allow(MsRestAzure::ApplicationTokenProvider).to receive(:new).and_return(mock_az_provider)
    allow(mock_az_provider).to receive(:get_authentication_header).and_return("TOKEN")
    stub_request(:get, expected_url).to_return(body: JSON.dump(metric_resp))

  end

  context "When metric not over thresholds" do
    it "Returns ok" do
      check_instance.run

      expect(check_instance).to have_received(:ok)
    end

    it "Retrieves the metric to compare" do
      check_instance.run

      expect(WebMock).to have_requested(:get, expected_url).with { |req|
        expect(req.headers["Authorization"]).to eq("TOKEN")
      }
    end
  end

  context "When last metric value is null" do
    let(:value2) { "2.0" }
    let(:value3) { nil }
    let(:critical) { "3.0" }
    it "Uses the last entry with a value" do
      check_instance.run

      expect(check_instance).to have_received(:ok)
    end
  end

  context "When no metric has a value" do
    let(:value1) { nil }
    let(:value2) { nil }
    let(:value3) { nil }
    it "Returns an known response" do
      check_instance.run

      expect(check_instance).to have_received(:unknown)
    end
  end

  context "When response has multiple entries in the value field" do
    let(:value_list) { [value_obj2, value_obj] }
    let(:value_obj2) {
      {
        id: "/subscriptions/576b7196-d42b-4b63-b696-af3ff33269a7/resourceGroups/test-group-1/providers/Microsoft.Network/virtualNetworkGateways/test-gateway/providers/Microsoft.Insights/metrics/TunnelAverageBandwidth",
        name: {
          localizedValue: "Tunnel Bandwidth",
          value: "TunnelAverageBandwidth"
        },
        resourceGroup: "test-group-1",
        timeseries: [
          {
            data: [
              {
                average: "4.0",
                timeStamp: "2018-01-26T16:56:00+00:00"
              }
            ]
          }
        ]
      }
    }

    it "Checks all values returned" do
      check_instance.run

      expect(check_instance).to have_received(:critical)
    end
  end

  context "When response has no timeseries" do
    let(:value_obj) {
      {
        id: "/subscriptions/576b7196-d42b-4b63-b696-af3ff33269a7/resourceGroups/test-group-1/providers/Microsoft.Network/virtualNetworkGateways/test-gateway/providers/Microsoft.Insights/metrics/TunnelAverageBandwidth",
        name: {
          localizedValue: "Tunnel Bandwidth",
          value: "TunnelAverageBandwidth"
        },
        resourceGroup: "test-group-1",
        timeseries: []
      }
    }

    it "Returns an known response" do
      check_instance.run

      expect(check_instance).to have_received(:unknown)
    end
  end

  context "When response has multiple time series" do
    let(:value_obj) {
      {
        id: "/subscriptions/576b7196-d42b-4b63-b696-af3ff33269a7/resourceGroups/test-group-1/providers/Microsoft.Network/virtualNetworkGateways/test-gateway/providers/Microsoft.Insights/metrics/TunnelAverageBandwidth",
        name: {
          localizedValue: "Tunnel Bandwidth",
          value: "TunnelAverageBandwidth"
        },
        resourceGroup: "test-group-1",
        timeseries: [
          {
            data: [
              {
                average: "4.0",
                timeStamp: "2018-01-26T16:56:00+00:00"
              }
            ]
          },
          {
            data: [
              {
                average: "1.0",
                timeStamp: "2018-01-26T16:56:00+00:00"
              }
            ]
          }
        ]
      }
    }

    it "Checks the last value in each time series" do
      check_instance.run

      expect(check_instance).to have_received(:critical)
    end
  end

  context "When response has no data entry" do
    let(:value_obj) {
      {
        id: "/subscriptions/576b7196-d42b-4b63-b696-af3ff33269a7/resourceGroups/test-group-1/providers/Microsoft.Network/virtualNetworkGateways/test-gateway/providers/Microsoft.Insights/metrics/TunnelAverageBandwidth",
        name: {
          localizedValue: "Tunnel Bandwidth",
          value: "TunnelAverageBandwidth"
        },
        resourceGroup: "test-group-1",
        timeseries: [
          {
            data: []
          }
        ]
      }
    }

    it "Returns an unknown response" do
      check_instance.run

      expect(check_instance).to have_received(:unknown)
    end
  end

  context "When no tenant, client, secret, and subscription given" do
    it "Uses the values from the env" do
      check_instance.run

      expect(MsRestAzure::ApplicationTokenProvider).to have_received(:new).with(
        "armtenantid",
        "armclientid",
        "armclientsecret"
      )
    end
  end

  context "When tenant, client, secret, and subscription given" do
    let(:script_args) { [
      "--resource", resource_id,
      "--metric", metric_name,
      "--critical", critical,
      "--tenant", tenant,
      "--client", clientId,
      "--clientSecret", clientSecret
    ] }

    let(:tenant) { "tenant" }
    let(:clientId) { "clientId" }
    let(:clientSecret) { "clientSecret" }

    it "uses the values supplied instead of the env" do
      check_instance.run

      expect(MsRestAzure::ApplicationTokenProvider).to have_received(:new).with(
        tenant,
        clientId,
        clientSecret
      )
    end
  end

  context "When no thresholds given" do
    let(:script_args) { [
      "--resource", resource_id,
      "--metric", metric_name
    ] }

    it "Returns an error" do
      check_instance.run

      expect(check_instance).to have_received(:critical)
    end
  end

  context "When metric over thresholds given" do
    context "And the metric exceeds the warning" do
      let(:value3) { "4.0" }
      let(:warning) { "3.0" }
      let(:critical) { "5.0" }

      it "Returns warning" do
        check_instance.run

        expect(check_instance).to have_received(:warning)
      end
    end

    context "And the metric exceeds the critical" do
      let(:value3) { "4.0" }
      let(:warning) { "3.0" }
      let(:critical) { "3.5" }
      it "Returns a critical" do
        check_instance.run

        expect(check_instance).to have_received(:critical)
      end
    end
  end

  context "When metric under thresholds given" do
    context "And the metric lower the warning" do
      let(:value3) { "2.0" }
      let(:warning_under) { "3.0" }
      let(:critical_under) { "1.0" }

      it "Returns warning" do
        check_instance.run

        expect(check_instance).to have_received(:warning)
      end
    end

    context "And the metric lower the critical" do
      let(:value3) { "2.0" }
      let(:warning_under) { "3.0" }
      let(:critical_under) { "4.0" }

      it "Returns a critical" do
        check_instance.run

        expect(check_instance).to have_received(:critical)
      end
    end
  end

  def mock_result_methods(instance)
    allow(instance).to receive(:unknown)
    allow(instance).to receive(:critical)
    allow(instance).to receive(:warning)
    allow(instance).to receive(:ok)
  end
end
