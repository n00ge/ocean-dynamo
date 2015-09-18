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
        self.dynamo_resource = nil
        self.dynamo_table = nil
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
        if table_exists?(dynamo_table)
          wait_until_table_is_active
          self.table_connected = true
          update_table_if_required
        else
          raise(TableNotFound, table_full_name) unless table_create_policy
          create_table
        end
      end


      def setup_dynamo
        self.dynamo_client ||= Aws::DynamoDB::Client.new
        self.dynamo_resource ||= Aws::DynamoDB::Resource.new(client: dynamo_client)
        self.dynamo_table = dynamo_resource.table(table_full_name)
      end


      def table_exists?(table)
        return true if table.data_loaded?
        begin
          table.load
        rescue Aws::DynamoDB::Errors::ResourceNotFoundException
          return false
        end
        true
      end


      def wait_until_table_is_active
        loop do
          case dynamo_table.table_status
          when "ACTIVE"
            update_table_if_required
            return
          when "UPDATING", "CREATING"
            sleep 1
            next
          when "DELETING"
            sleep 1 while table_exists?(dynamo_table)
            create_table
            return
          else
            raise UnknownTableStatus.new("Unknown DynamoDB table status '#{dynamo_table.table_status}'")
          end
        end
      end


       def create_table
        attrs = table_attribute_definitions  # This already includes secondary indices
        keys = table_key_schema
        options = {
          table_name: table_full_name,
          attribute_definitions: attrs,
          key_schema: keys,
          provisioned_throughput: {
            read_capacity_units: table_read_capacity_units,
            write_capacity_units: table_write_capacity_units
          }
        }
        lsi = local_secondary_indexes.collect { |n| local_secondary_index_declaration n }
        options[:local_secondary_indexes] = lsi unless lsi.blank?
        dynamo_resource.create_table(options)
        sleep 1 until dynamo_table.table_status == "ACTIVE"
        setup_dynamo
        true
      end


     def update_table_if_required
        attrs = table_attribute_definitions
        active_attrs = []
        dynamo_table.attribute_definitions.each do |k| 
          active_attrs << { attribute_name: k.attribute_name, attribute_type: k.attribute_type }
        end
        return false if active_attrs == attrs
        options = { attribute_definitions: attrs }
        dynamo_table.update(options)
        true
      end


      def table_attribute_definitions
        attrs = []
        attrs << { attribute_name: table_hash_key.to_s, attribute_type: attribute_type(table_hash_key) }
        attrs << { attribute_name: table_range_key.to_s, attribute_type: attribute_type(table_range_key) }  if table_range_key
        local_secondary_indexes.each do |name|
          attrs << { attribute_name: name, attribute_type: attribute_type(name) }
        end
        attrs
      end


      def table_key_schema(hash_key: table_hash_key, range_key: table_range_key)
        keys = []
        keys << { attribute_name: hash_key.to_s, key_type: "HASH" }
        keys << { attribute_name: range_key.to_s, key_type: "RANGE" } if range_key
        keys
      end


      def local_secondary_indexes
        @local_secondary_indexes ||= begin
          result = []
          fields.each do |name, metadata|
            (result << name) if metadata["local_secondary_index"]
          end
          result
        end
      end


      def local_secondary_index_declaration(name)
        { index_name: name,
          key_schema: table_key_schema(range_key: name),
          projection: { projection_type: "KEYS_ONLY" }
        }
      end


      def attribute_type(name)
        vals = fields[name][:type]
        case vals
        when :string, :serialized, :reference
          return "S"
        when :integer, :float, :datetime
          return "N"
        when :boolean
          return "B"
        else
          raise "Unknown OceanDynamo type: #{name} - #{vals.inspect}"
        end
      end


      def delete_table
        return false unless dynamo_table.data_loaded? && dynamo_table.table_status == "ACTIVE"
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
      super
    end

  end
end
