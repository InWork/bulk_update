require "bulk_update/version"
require "bulk_update/active_record_inflections"
require "active_record"

ActiveRecord::Base.send(:extend, BulkUpdate::ActiveRecordInflections)
