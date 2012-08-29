# BulkUpdate

Updates a large amount of Records in a highliy efficient way.
Enhances Active Record with a method for bulk inserts and a method for bulk updates. Both merthods are used for inserting or updating large amount of Records.

## Installation

Add this line to your application's Gemfile:

    gem 'bulk_update'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bulk_update

## Usage

### Bulk insert

Bulk insert inserts a large amount of data into as SQL-Bulk-Inserts. Example:
  columns = [:name, :value]
  values  = [['name1', 'value1'], ['name2', 'value2'], ['name3', 'value3']]
  Model.bulk_insert columns, values

### Bulk update

Bulk update updates a large amount of data. Update means, it creates new records, updates existing records which have changed and deletes old records. This is all done with ActiveRecord which means, all callbacks are executed.
You have to provide a columns as a key, which is used determine which records are new, have changed or has to be deleted. Only the values provided in the array 'values' are compared and will be updated. Example:

  columns = [:name, :value]
  values  = [['name1', 'value1'], ['name2', 'value2'], ['name3', 'value3']]

You have now the following entries in your database:
  +----+----------------+
  | id | name  | value  |
  +----+----------------+
  |  0 | name1 | value1 |
  |  1 | name2 | value2 |
  |  2 | name3 | value3 |
  +----+----------------+

  Model.bulk_insert columns, values
  values  = [['name1', 'value1.1'], ['name2', 'value2'], ['name4', 'value4.1']]
  Model.bulk_update columns, values, key: 'name'

You have now the following entries in your database:
  +----+------------------+
  | id | name  | value    |
  +----+------------------+
  |  0 | name1 | value1.1 |
  |  1 | name2 | value2   |
  |  3 | name4 | value4.1 |
  +----+------------------+


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
