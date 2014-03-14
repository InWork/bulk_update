ActiveRecord::Migration.create_table :my_hashes do |t|
  t.string :name
  t.string :value
  t.timestamps
end

ActiveRecord::Migration.create_table :my_date_time_hashes do |t|
  t.string :name
  t.string :value
  t.datetime :time_value
  t.timestamps
end

