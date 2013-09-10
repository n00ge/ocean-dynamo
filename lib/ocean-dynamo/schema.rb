module OceanDynamo
  class Base

    #
    # This is where the class is initialized
    #
    def self.primary_key(hash_key, range_key=nil)
      self.dynamo_client = nil
      self.dynamo_table = nil
      self.dynamo_items = nil
      self.table_name = compute_table_name
      self.table_name_prefix = nil
      self.table_name_suffix = nil
      self.fields = HashWithIndifferentAccess.new
      self.table_hash_key = hash_key
      self.table_range_key = range_key
      DEFAULT_ATTRIBUTES.each { |k, name, **pairs| attribute k, name, **pairs }
      nil
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
