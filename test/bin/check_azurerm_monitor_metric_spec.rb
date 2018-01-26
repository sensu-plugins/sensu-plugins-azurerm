require File.expand_path('../spec_helper', File.dirname(__FILE__))
require File.expand_path('../../bin/check-azurerm-monitor-metric', File.dirname(__FILE__))

require 'webmock/rspec'

describe "check monitor metric script" do
  subject(:check_instance) { CheckAzurermMonitorMetric.new(script_args) }
  let(:script_args) { [
    "--resource", resource_id,
    "--metric", metric_name,
    "--critical", critical
  ] }
  let(:resource_id) { "resource" }
  let(:metric_name) { "metric" }
  let(:critical) { "3.0" }

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
      value: [
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
                  average: "2.2",
                  timeStamp: "2018-01-26T16:56:00+00:00"
                },
                {
                  average: value1,
                  timeStamp: "2018-01-26T16:56:00+00:00"
                },
                {
                  average: value2,
                  timeStamp: "2018-01-26T16:57:00+00:00"
                }
              ]
            }
          ]
        }
      ]
    }
  }

  let(:value1) { "1.2" }
  let(:value2) { "2.2" }

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
    let(:value1) { "-2.0" }
    let(:value2) { nil }
    let(:critical) { "-1.0" }
    it "Uses the last entry with a value" do
      check_instance.run

      expect(check_instance).to have_received(:ok)
    end
  end

  context "When no metric has a value" do
    it "Returns an known response"
  end

  context "When response has multiple values" do
    it "Uses the last value entry"
  end

  context "When response has no timeseries" do
    it "Returns an known response"
  end

  context "When response has multiple time series" do
    it "Uses the last timeseries entry"
  end

  context "When response has no data entry" do
    it "Returns an known response"
  end

  context "When no tenant, client, secret, and subscription given" do
    it "Uses the values from the env"
  end

  context "When tenant, client, secret, and subscription given" do
    it "uses the values supplied instead of the env"
  end

  context "When no thresholds given" do
    it "Returns an error"
  end

  context "When metric over thresholds given" do
    context "And the metric exceeds the warning" do
      it "Returns warning"
    end

    context "And the metric exceeds the critical" do
      it "Returns a critical"
    end
  end

  context "When metric under thresholds given" do
    context "And the metric lower the warning" do
      it "Returns warning"
    end

    context "And the metric lower the critical" do
      it "Returns a critical"
    end
  end

  def mock_result_methods(instance)
    allow(instance).to receive(:critical)
    allow(instance).to receive(:warning)
    allow(instance).to receive(:ok)
  end
end
