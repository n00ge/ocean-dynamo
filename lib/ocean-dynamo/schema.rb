module OceanDynamo
  module Schema

    # ---------------------------------------------------------
    #
    #  Class methods
    #
    # ---------------------------------------------------------

    def dynamo_schema(*)
      super
      # Finally return the full table name
      table_full_name
    end


    def define_attribute_accessors(name)
      name = name.to_s
      self.class_eval "def #{name}; read_attribute('#{name}'); end"
      self.class_eval "def #{name}=(value); write_attribute('#{name}', value); end"
      self.class_eval "def #{name}?; read_attribute('#{name}').present?; end"
    end


    def compute_table_name
      name.pluralize.underscore.gsub('/', '_')
    end


    def table_full_name
      "#{table_name_prefix}#{table_name}#{table_name_suffix}"
    end


    def attribute(name, type=:string, default: nil, **extra)
      raise DangerousAttributeError, "#{name} is defined by OceanDynamo" if self.dangerous_attributes.include?(name.to_s)
      attr_accessor name
      fields[name.to_s] = {type: type, default: default}.merge(extra)
    end


    def global_secondary_index(hash_key, range_key=nil, 
                               projection: :keys_only,
                               read_capacity_units: table_read_capacity_units,
                               write_capacity_units: table_write_capacity_units)
      if range_key
        name = "#{hash_key}_#{range_key}"
        keys = [hash_key.to_s, range_key.to_s]
      else
        name = "#{hash_key}"
        keys = [hash_key.to_s]
      end
      self.global_secondary_indexes[name] = { 
        "keys" => keys, 
        "projection_type" => projection.to_s.upcase,
        "read_capacity_units" => read_capacity_units,
        "write_capacity_units" => write_capacity_units
      }   
    end


    protected

    def dangerous_attributes # :nodoc:
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
