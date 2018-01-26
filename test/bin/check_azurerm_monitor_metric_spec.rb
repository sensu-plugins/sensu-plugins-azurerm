require File.expand_path('../spec_helper', File.dirname(__FILE__))
require File.expand_path('../../bin/check-azurerm-monitor-metric', File.dirname(__FILE__))

require 'webmock/rspec'

describe "check monitor metric script" do
  subject(:check_instance) { CheckAzurermMonitorMetric.new(script_args) }
  let(:script_args) { [] }
  let(:expected_url) { "http://localhost:8080/metrics" }
  let(:mock_az_provider) { double }

  before(:each) do
    mock_result_methods(check_instance)
    allow(MsRestAzure::ApplicationTokenProvider).to receive(:get).and_return(mock_az_provider)
  end

  context "When metric not over thresholds" do
    it "Returns ok" do
      check_instance.run

      expect(instance).to have_received(:ok)
    end

    it "Retrieves the metric to compare"
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

  def mock_result_methods(instance)
    allow(instance).to receive(:critical)
    allow(instance).to receive(:warning)
    allow(instance).to receive(:ok)
  end

end


