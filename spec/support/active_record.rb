require 'active_record'
require 'active_record/version'

SQLITE3_SPEC = {
  adapter:  'sqlite3',
  database: ':memory:',
  encoding: 'utf8'
}

MYSQL_SPEC = {
  adapter:  'mysql2',
  host:     'localhost',
  database: 'bulk_update_test',
  username: 'root',
  password: '123456',
  encoding: 'utf8'
}

PG_SPEC = {
  adapter:  'postgresql',
  host:     'localhost',
  database: 'bulk_update_test',
  username: 'pk',
  password: '123456',
  encoding: 'utf8'
}

DB_SPEC = SQLITE3_SPEC
# DB_SPEC = MYSQL_SPEC
# DB_SPEC = PG_SPEC

puts "Testing ActiveRecord #{ActiveRecord::VERSION::STRING} #{DB_SPEC[:adapter]}-adapter"

# drops and create need to be performed with a connection to the 'postgres' (system) database
if DB_SPEC[:adapter] == 'mysql2'
  ActiveRecord::Base.establish_connection(DB_SPEC.merge(database: nil))
elsif DB_SPEC[:adapter] == 'postgresql'
  ActiveRecord::Base.establish_connection(DB_SPEC.merge(database: 'postgres', schema_search_path: 'public'))
end

# Drop old DB and create a new one
if DB_SPEC[:adapter] == 'mysql2' || DB_SPEC[:adapter] == 'postgresql'
  ActiveRecord::Base.connection.drop_database DB_SPEC[:database] rescue nil
  ActiveRecord::Base.connection.create_database(DB_SPEC[:database])
end

# Establish connection
ActiveRecord::Base.establish_connection(DB_SPEC)
# Migrate DB
ActiveRecord::Migrator.up 'db/migrate'
load 'spec/support/schema.rb'


module ActiveModel::Validations
  # Extension to enhance `should have` on AR Model instances.  Calls
  # model.valid? in order to prepare the object's errors object.
  #
  # You can also use this to specify the content of the error messages.
  #
  # @example
  #
  #     model.should have(:no).errors_on(:attribute)
  #     model.should have(1).error_on(:attribute)
  #     model.should have(n).errors_on(:attribute)
  #
  #     model.errors_on(:attribute).should include("can't be blank")
  def errors_on(attribute)
    self.valid?
    [self.errors[attribute]].flatten.compact
  end
  alias :error_on :errors_on
end


RSpec.configure do |config|
  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
