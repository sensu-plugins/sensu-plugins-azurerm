require 'codeclimate-test-reporter'
# frozen_string_literal: true
CodeClimate::TestReporter.start

RSpec.configure do |c|
  c.formatter = :documentation
  c.color = true

  c.before(:suite) do
    Sensu::Plugin::CLI.class_variable_set(:@@autorun, Common)
  end
end

#
# DESCRIPTION:
#   Extension of common helper methods for testing.
#   Specifically, override trigger functions from Sensu::Plugin::Check::CLI
#   to enable better testability.
#
# DEPENDENCIES:
#   gem: azure_mgmt_compute
#   gem: sensu-plugin
#
# USAGE:
#
# NOTES:
#
# LICENSE:
#   Tom Harvey <github@ibuildstuff.co.uk>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#
module Common
  at_exit do
    exit! 0
  end

  def critical(msg = nil)
    "triggered critical: #{msg}"
  end

  def warning(msg = nil)
    "triggered warning: #{msg}"
  end

  def ok(msg = nil)
    "triggered ok: #{msg}"
  end

  def unknown(msg = nil)
    "triggered unknown: #{msg}"
  end
end
