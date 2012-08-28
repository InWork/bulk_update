require 'rubygems'
require 'bundler/setup'
require 'support/active_record'
require 'support/my_hash'

require 'bulk_update'


RSpec.configure do |config|
  config.color_enabled = true
  config.formatter     = 'documentation'
end
