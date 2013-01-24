module BulkUpdate
  module ActiveRecordInflections
    #
    # Clone the database structure of a table
    def clone_table args = {}
      if args[:to]
        case ActiveRecord::Base.connection_config[:adapter]
        when 'sqlite3'
          ActiveRecord::Base.connection.execute "CREATE TABLE `#{args[:to]}` AS SELECT * FROM `#{table_name}` LIMIT 1"
          ActiveRecord::Base.connection.execute "DELETE FROM `#{args[:to]}`"
        when 'postgresql'
          ActiveRecord::Base.connection.execute "CREATE TABLE \"#{args[:to]}\" (LIKE \"#{table_name}\" INCLUDING DEFAULTS INCLUDING CONSTRAINTS INCLUDING INDEXES);"
        else
          ActiveRecord::Base.connection.execute "CREATE TABLE `#{args[:to]}` LIKE `#{table_name}`"
        end
      end
    end


    def insert_str element
      if element.class == Fixnum || element.class == Float
        element
      elsif element.class == NilClass
        'NULL'
      else
        if element.to_s[0] == '(' || element.to_s.downcase == 'true' || element.to_s.downcase == 'false'
          element.to_s
        else
          "'#{element}'"
        end
      end
    end


    #
    # Bulk insert records
    def bulk_insert columns, values, args = {}
      # Limit inserts
      max_records_per_insert = args[:max_records_per_insert] || 100
      table = args[:into] || table_name
      columns = columns.clone

      # Add timestamp
      timestamp = Time.now
      add_timestamp = false
      add_updated_at = false
      unless columns.map(&:to_sym).include?(:created_at)
        columns << :created_at
        add_created_at = true
      end
      unless columns.map(&:to_sym).include?(:updated_at)
        columns << :updated_at
        add_updated_at = true
      end

      if table_name
        # Create header for insert with all column names
        case ActiveRecord::Base.connection_config[:adapter]
        when 'postgresql'
          columns = columns.map! { |c| "\"#{c}\"" }
          insert_head = "INSERT INTO \"#{table}\" (#{columns.join(', ')})"
        else
          columns = columns.map!{ |c| "`#{c}`" }
          insert_head = "INSERT INTO `#{table}` (#{columns.join(', ')})"
        end

        # Create inserts
        inserts = []
        values.each do |values_per_record|
          values_per_record = values_per_record.clone
          values_per_record << timestamp if add_created_at
          values_per_record << timestamp if add_updated_at
          inserts << "(#{values_per_record.map{ |e| insert_str(e) }.join(', ')})"
          if inserts.count > max_records_per_insert
            ActiveRecord::Base.connection.execute "#{insert_head} VALUES #{inserts.join(', ')}"
            inserts.clear
          end
        end
        ActiveRecord::Base.connection.execute "#{insert_head} VALUES #{inserts.join(', ')}" unless inserts.empty?
      end
    end


    #
    # Create, update and delete Records according to a set of new values through ActiveRecord but optimized for performance by
    # finding all diferences by SQL.
    def bulk_update columns, values, args = {}
      temp_table = "#{table_name}_temp_table_#{$$}"
      key = args[:key] || args[:keys] || 'id'
      condition = args[:condition]
      exclude_fields = args[:exclude_fields]
      insert = args[:insert].nil? ? true : args[:insert]
      update = args[:update].nil? ? true : args[:update]
      remove = args[:remove].nil? ? true : args[:remove]

      # Clone temp-table and load it
      clone_table to: temp_table
      bulk_insert columns, values, into: temp_table

      # Find differences and create, update and delete these through ActiveRecord to handle Callbacks, etc.
      create(get_new_records for: self, compare_with: temp_table, on: key, condition: condition, exclude_fields: exclude_fields) if insert
      if update
        get_updated_records(for: self, compare_with: temp_table, on: key, condition: condition, exclude_virtual: args[:exclude_virtual], exclude_fields: exclude_fields).each do |id, new_attributes|
          find(id).update_attributes new_attributes
        end
      end
      destroy(get_deleted_records for: self, compare_with: temp_table, on: key, condition: condition, exclude_virtual: args[:exclude_virtual]) if remove

    ensure
      # Drop temp table
      ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS #{temp_table}"
    end


    #
    # Exclude List
    def default_exclude
      ['id', 'version', 'created_at', 'updated_at']
    end


    #
    # Compare Table of args[:model] with its temporary table args[:compare_with] and return all new records as a Array of Hashes
    def get_new_records args = {}
      model = args[:for] || self
      compare_table = args[:compare_with]
      keys = args[:on] || 'id'
      exclude = args[:exclude_fields] || []
      exclude |= default_exclude

      # Generate conditions for query and sub-query
      conditions = []
      conditions2 = []
      conditions << "#{args[:condition].gsub('--tt--', compare_table)}" if args[:condition]
      conditions2 << "#{args[:condition].gsub('--tt--', model.table_name)}" if args[:condition]
      if keys.class == String || keys.class == Symbol
        key = keys.to_s
      else
        key = keys[0].to_s
        conditions2 << keys[1..-1].map{|k| "#{model.table_name}.#{k.to_s} = #{compare_table}.#{k.to_s}" }
      end

      # Generate and execute SQL-Statement
      condition = conditions.join(' AND ')
      condition2 = conditions2.join(' AND ')
      sql = "SELECT * FROM #{compare_table} WHERE #{condition} #{'AND' unless conditions.blank?} #{compare_table}.#{key} NOT IN " +
            "(SELECT #{key} FROM #{model.table_name} #{'WHERE' unless conditions2.blank?} #{condition2})"
      results = ActiveRecord::Base.connection.execute sql

      # Generate Array with Hashes of all new records
      new_records = []
      keys_to_log = []
      results.each do |attributes|
        attributes = attributes2array(attributes)
        new_records << result2hash(attributes, exclude)
        keys_to_log << new_records.last[key.to_sym]
      end
      args[:logger].info "New Records for Model #{model.to_s}: #{keys_to_log.join(', ')}" unless keys_to_log.blank? || args[:logger].blank?
      new_records
    end


    #
    # Compare Table of args[:model] with its temporary table args[:compare_with] and return all updated records as a Hash of Hashes whose
    # key is the ID of the changed record
    def get_updated_records args = {}
      model = args[:for] || self
      compare_table = args[:compare_with]
      keys = args[:on] || 'id'
      exclude = args[:exclude_fields] || []
      exclude |= default_exclude
      exclude_virtual = args[:exclude_virtual].nil? ? false : args[:exclude_virtual]

      # Generate conditions for query and sub-query
      conditions = []
      conditions2 = []
      conditions << "NOT #{model.table_name}.virtual" if exclude_virtual
      if keys.class == String || keys.class == Symbol
        key = keys.to_s
        conditions << "#{model.table_name}.#{key} = #{compare_table}.#{key}"
        exclude |= [keys.to_s]
      else
        key = keys[0].to_s
        conditions |= keys.map{|k| "#{model.table_name}.#{k.to_s} = #{compare_table}.#{k.to_s}" }
        exclude |= keys.map(&:to_s)
      end
      conditions << "#{args[:condition].gsub('--tt--', model.table_name)} AND #{args[:condition].gsub('--tt--', compare_table)}" if args[:condition]
      model.attribute_names.each do |an|
        unless exclude.include?(an)
          if ActiveRecord::Base.connection_config[:adapter] =~ /mysql?/
            conditions2 << "NOT #{model.table_name}.#{an} <=> #{compare_table}.#{an}" unless exclude.include?(an)
          else
            conditions2 << "NOT (#{model.table_name}.#{an} = #{compare_table}.#{an} OR (#{model.table_name}.#{an} IS NULL AND #{compare_table}.#{an} IS NULL))"
          end
        end
      end

      # Generate and execute SQL-Statement
      condition = conditions.join(' AND ')
      condition += " AND (#{conditions2.join(' OR ')})" unless conditions2.blank?
      compare_columns = attribute_names.select { |e| e != 'id' }.map { |e| "#{compare_table}.#{e}" }.join(', ')
      sql = "SELECT #{model.table_name}.id, #{compare_columns} FROM #{model.table_name}, #{compare_table} WHERE #{condition}"
      results = ActiveRecord::Base.connection.execute sql

      # Generate Hash with id as the key and values as a Hashes of all changed records
      results_hash = {}
      keys_to_log = []
      results.each do |attributes|
        attributes = attributes2array(attributes)
        id = attributes[0]
        results_hash[id] = result2hash attributes, exclude
        keys_to_log << (args[:debug] ? model.find(id).send(key) : id)
      end
      args[:logger].info "Change Records for Model #{model.to_s}: #{keys_to_log.join(', ')}" unless keys_to_log.blank? || args[:logger].blank?

      results_hash
    end


    #
    # Compare Table of args[:model] with its temporary table args[:compare_with] and return all deleted records as a Array of IDs
    def get_deleted_records args = {}
      model = args[:for] || self
      compare_table = args[:compare_with]
      keys = args[:on] || 'id'
      exclude_virtual = args[:exclude_virtual].nil? ? false : args[:exclude_virtual]

      # Generate conditions for query and sub-query
      conditions = []
      conditions2 = []
      conditions << "NOT #{model.table_name}.virtual" if exclude_virtual
      conditions << "#{args[:condition].gsub('--tt--', model.table_name)}" if args[:condition]
      conditions2 << "#{args[:condition].gsub('--tt--', compare_table)}" if args[:condition]
      if keys.class == String || keys.class == Symbol
        key = keys.to_s
      else
        key = keys[0].to_s
        conditions2 |= keys[1..-1].map{|k| "#{model.table_name}.#{k.to_s} = #{compare_table}.#{k.to_s}" }
      end

      # Generate and execute SQL-Statement
      condition = conditions.join(' AND ')
      condition2 = conditions2.join(' AND ')
      sql = "SELECT id, #{key} FROM #{model.table_name} WHERE #{condition} #{'AND' unless conditions.blank?} #{model.table_name}.#{key} NOT IN " +
            "(SELECT #{key} FROM #{compare_table} #{'WHERE' unless conditions2.blank?} #{condition2})"
      results = ActiveRecord::Base.connection.execute sql

      # Generate Array with ids of all deleted records
      deleted_records = []
      keys_to_log = []
      results.each do |attributes|
        attributes = attributes2array(attributes)
        deleted_records << attributes[0]
        keys_to_log << attributes[1]
      end
      args[:logger].info "Deleting Records from Model #{model.to_s}: #{keys_to_log.join(', ')}" unless keys_to_log.blank? || args[:logger].blank?
      deleted_records
    end


  private


    def result2hash(attributes, exclude, attribute_nr = 0)
      hash = {}
      attribute_names.each do |an|
        hash[an.to_sym] = attributes[attribute_nr] unless exclude.include?(an)
        attribute_nr += 1
      end
      hash
    end


    def attributes2array(attributes)
      ActiveRecord::Base.connection_config[:adapter] == 'postgresql' ? attributes.map{ |e| e.last } : attributes
    end

  end
end
