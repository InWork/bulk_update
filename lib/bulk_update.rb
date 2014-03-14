require "bulk_update/version"
require "bulk_update/active_record_inflections"
require "active_record"
require 'active_support/time_with_zone'

ActiveRecord::Base.send(:extend, BulkUpdate::ActiveRecordInflections)
