module OceanDynamo
  module Tables

    def self.included(base)
      base.extend(ClassMethods)
    end
  

    # ---------------------------------------------------------
    #
    #  Class methods
    #
    # ---------------------------------------------------------

    module ClassMethods

      def dynamo_schema(table_hash_key=:id, 
                        table_range_key=nil,
                        table_name: compute_table_name,
                        table_name_prefix: nil,
                        table_name_suffix: nil,
                        read_capacity_units: 10,
                        write_capacity_units: 5,
                        connect: :late,
                        create: false,
                        **keywords,
                        &block)
        self.dynamo_client = nil
        self.dynamo_table = nil
        self.dynamo_items = nil
        self.table_connected = false
        self.table_connect_policy = connect
        self.table_create_policy = create
        self.table_hash_key = table_hash_key
        self.table_range_key = table_range_key
        self.table_name = table_name
        self.table_name_prefix = table_name_prefix
        self.table_name_suffix = table_name_suffix
        self.table_read_capacity_units = read_capacity_units
        self.table_write_capacity_units = write_capacity_units
        # Connect if asked to
        establish_db_connection if connect == true
      end


      def establish_db_connection
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


      def setup_dynamo
        self.dynamo_client ||= AWS::DynamoDB.new
        self.dynamo_table = dynamo_client.tables[table_full_name]
        self.dynamo_items = dynamo_table.items
      end


      def wait_until_table_is_active
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


      def set_dynamo_table_keys
        hash_key_type = fields[table_hash_key][:type]
        hash_key_type = :string if hash_key_type == :reference
        dynamo_table.hash_key = [table_hash_key, hash_key_type]

        if table_range_key
          range_key_type = generalise_range_key_type
          dynamo_table.range_key = [table_range_key, range_key_type]
        end
      end


      def create_table
        hash_key_type = fields[table_hash_key][:type]
        hash_key_type = :string if hash_key_type == :reference
        range_key_type = generalise_range_key_type

        self.dynamo_table = dynamo_client.tables.create(table_full_name, 
          table_read_capacity_units, table_write_capacity_units,
          hash_key: { table_hash_key => hash_key_type},
          range_key: table_range_key && { table_range_key => range_key_type }
        )
        sleep 1 until dynamo_table.status == :active
        setup_dynamo
        true
      end


      def generalise_range_key_type
        return false unless table_range_key
        t = fields[table_range_key][:type]
        return :string if t == :string
        return :number if t == :integer
        return :number if t == :float
        return :number if t == :datetime
        raise "Unsupported range key type: #{t}"
      end


      def delete_table
        return false unless dynamo_table.exists? && dynamo_table.status == :active
        dynamo_table.delete
        true
      end

    end
  

    # ---------------------------------------------------------
    #
    #  Instance methods
    #
    # ---------------------------------------------------------

    def initialize(*)
      @dynamo_item = nil
      super
    end

  end
end
