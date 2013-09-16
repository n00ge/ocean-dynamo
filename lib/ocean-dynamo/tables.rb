module OceanDynamo
  class Base

    def self.establish_db_connection
      setup_dynamo  
      if dynamo_table.exists?
        wait_until_table_is_active
        self.table_connected = true
      else
        raise(TableNotFound, table_full_name) unless table_create_policy
        create_table
      end
      set_dynamo_table_keys
    end


    def self.setup_dynamo
      #self.dynamo_client = AWS::DynamoDB::Client.new(:api_version => '2012-08-10') 
      self.dynamo_client ||= AWS::DynamoDB.new
      self.dynamo_table = dynamo_client.tables[table_full_name]
      self.dynamo_items = dynamo_table.items
    end


    def self.wait_until_table_is_active
      loop do
        case dynamo_table.status
        when :active
          set_dynamo_table_keys
          return
        when :updating, :creating
          sleep 1
          next
        when :deleting
          sleep 1 while dynamo_table.exists?
          create_table
          return
        else
          raise UnknownTableStatus.new("Unknown DynamoDB table status '#{dynamo_table.status}'")
        end
      end
    end


    def self.set_dynamo_table_keys
      hash_key_type = fields[table_hash_key][:type]
      hash_key_type = :string if hash_key_type == :reference
      dynamo_table.hash_key = [table_hash_key, hash_key_type]

      if table_range_key
        range_key_type = fields[table_range_key][:type]
        #range_key_type = :string if range_key_type == :reference
        dynamo_table.range_key = [table_range_key, range_key_type]
      end
    end


    def self.create_table
      hash_key_type = fields[table_hash_key][:type]
      hash_key_type = :string if hash_key_type == :reference

      range_key_type = table_range_key && fields[table_range_key][:type]
      #range_key_type = :string if range_key_type == :reference

      self.dynamo_table = dynamo_client.tables.create(table_full_name, 
        table_read_capacity_units, table_write_capacity_units,
        hash_key: { table_hash_key => hash_key_type},
        range_key: table_range_key && { table_range_key => range_key_type }
      )
      sleep 1 until dynamo_table.status == :active
      setup_dynamo
      true
    end


    def self.delete_table
      return false unless dynamo_table.exists? && dynamo_table.status == :active
      dynamo_table.delete
      true
    end

  end
end
