require 'rubygems'
require 'bundler/setup'

require 'bulk_update'
require 'support/active_record'
require 'support/my_hash'


RSpec.configure do |config|
  config.color_enabled = true
  config.formatter     = 'documentation'
end
