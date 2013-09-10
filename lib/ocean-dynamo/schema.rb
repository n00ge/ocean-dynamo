module OceanDynamo
  class Base


    def self.dynamo_schema(table_hash_key=:uuid, table_range_key=nil,
                           table_name: compute_table_name,
                           table_name_prefix: nil,
                           table_name_suffix: nil,
                           read_capacity_units: 10,
                           write_capacity_units: 5,
                           connect: true,
                           &block)
      # Set class vars
      self.dynamo_client = nil
      self.dynamo_table = nil
      self.dynamo_items = nil
      self.table_hash_key = table_hash_key
      self.table_range_key = table_range_key
      self.table_name = table_name
      self.table_name_prefix = table_name_prefix
      self.table_name_suffix = table_name_suffix
      self.table_read_capacity_units = read_capacity_units
      self.table_write_capacity_units = write_capacity_units
      # Init
      self.fields = HashWithIndifferentAccess.new
      attribute table_hash_key, :string, default: ''
      DEFAULT_ATTRIBUTES.each { |name, type, **pairs| attribute name, type, **pairs }
      block.call
      # Connect to AWS
      establish_db_connection if connect
      # Finally return the full table name
      table_full_name
    end


    def self.set_table_name(name)
      self.table_name = name
      true
    end


    def self.set_table_name_prefix(prefix)
      self.table_name_prefix = prefix
      true
    end


    def self.set_table_name_suffix(suffix)
      self.table_name_suffix = suffix
      true
    end


    def self.compute_table_name
      name.pluralize.underscore
    end


    def self.table_full_name
      "#{table_name_prefix}#{table_name}#{table_name_suffix}"
    end


    def self.read_capacity_units(units)
      self.table_read_capacity_units = units
    end


    def self.write_capacity_units(units)
      self.table_write_capacity_units = units
    end


    def self.attribute(name, type=:string, **pairs)
      attr_accessor name
      fields[name.to_s] = {type: type, default: pairs[:default]}
    end

  end
end
