# BulkUpdate

Updates a large amount of Records in a highliy efficient way.
Enhances Active Record with a method for bulk inserts and a method for bulk updates. Both methods are used for inserting or updating large amount of Records.

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

Bulk update updates a large amount of data. Update means, it creates new records, updates existing records which have changed and deletes old records. This is all done with ActiveRecord which means, all callbacks are executed. The difference between the old and the new records are fully discovered by SQL.

You have to provide a columns as a key, which is used determine which records are new, have changed or has to be deleted. Only the values provided in the array 'values' are compared and will be updated. Example:

    columns = [:name, :value]
    values  = [['name1', 'value1'], ['name2', 'value2'], ['name3', 'value3']]
    Model.bulk_insert columns, values

You have now the following entries in your database:
<pre>
+----+-------+--------+-----------+------------+
| id | name  | value  | timestamp | updated_at |
+----+-------+--------+-----------+------------+
|  0 | name1 | value1 |        t1 |         t1 |
|  1 | name2 | value2 |        t1 |         t1 |
|  2 | name3 | value3 |        t1 |         t1 |
+----+-------+--------+-----------+------------+
</pre>

If you now do a bulk update:

    values  = [['name1', 'value1.1'], ['name2', 'value2'], ['name4', 'value4.1']]
    Model.bulk_update columns, values, key: 'name'

You have now the following entries in your database:
<pre>
+----+-------+----------+-----------+------------+
| id | name  | value    | timestamp | updated_at |
+----+-------+----------+-----------+------------+
|  0 | name1 | value1.1 |        t1 |         t2 |
|  1 | name2 | value2   |        t1 |         t1 |
|  3 | name4 | value4.1 |        t2 |         t2 |
+----+-------+----------+-----------+------------+
</pre>

## How it works

### Bulk insert

Bulk insert uses the bulk insert feature of SQL (`INSERT INTO tbl_name (col1,col2,col3) VALUES(v1,v2,v3),(v4,v5,v6),(v7,v8,v9);`)

You can specify the max records per insert with the argument `:max_records_per_insert` (default is 100). After these amount of records, the SQL is sent to the database.

### Bulk update

First, a temp-table will be created with the same structure as the original table. Then, all new records are inserted by bulk-inserts into the temp-table.
When the temp table was loaded, the difference between these 2 tables are discovered in 3 steps: New records, changed records and deleted records.
All new, changed and deleted records are handled by ActiveRecord. This ensures, all callbacks get executed as defined.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
