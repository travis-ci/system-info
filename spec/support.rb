require 'simplecov'
require 'system_info'

RSpec.configure do |c|
  c.filter_run_excluding(integration: true) unless ENV['INTEGRATION_SPECS']
end
