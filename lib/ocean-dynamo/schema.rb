module OceanDynamo
  class Base


    def self.dynamo_schema(table_hash_key=:uuid, 
                           table_range_key=nil,
                           table_name: compute_table_name,
                           table_name_prefix: nil,
                           table_name_suffix: nil,
                           read_capacity_units: 10,
                           write_capacity_units: 5,
                           connect: :late,
                           create: false,
                           locking: :lock_version,
                           timestamps: [:created_at, :updated_at],
                           &block)
      # Set class vars
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
      self.lock_attribute = locking
      self.timestamp_attributes = timestamps
      # Init
      self.fields = HashWithIndifferentAccess.new
      attribute table_hash_key, :string, default: ""
      timestamp_attributes.each { |name| attribute name, :datetime } if timestamp_attributes
      attribute(lock_attribute, :integer, default: 0) if locking
      block.call
      # Define attribute accessors
      fields.each do |name, md| 
        name = name.to_s
        # We define accessors even if the name is 'id' (for which we already have methods)
        self.class_eval "def #{name}; read_attribute('#{name}'); end"
        self.class_eval "def #{name}=(value); write_attribute('#{name}', value); end"
        self.class_eval "def #{name}?; read_attribute('#{name}').present?; end"
      end
      # Connect to AWS
      establish_db_connection if connect == true
      # Finally return the full table name
      table_full_name
    end


    def self.compute_table_name
      name.pluralize.underscore
    end


    def self.table_full_name
      "#{table_name_prefix}#{table_name}#{table_name_suffix}"
    end


    def self.attribute(name, type=:string, **pairs)
      raise DangerousAttributeError, "#{name} is defined by OceanDynamo" if self.dangerous_attributes.include?(name.to_s)
      attr_accessor name
      fields[name.to_s] = {type: type, default: pairs[:default]}
    end


    protected

    def self.dangerous_attributes # :nodoc:
      self.public_methods(false).collect do |sym|
        str = sym.to_s
        if str.end_with?("?", "=")
          str[0...-1]
        else
          str
        end
      end.uniq
    end

  end
end
