module OceanDynamo
  class Base
    #include ActiveModel::DeprecatedMassAssignmentSecurity
    #include ActiveModel::ForbiddenAttributesProtection

    attr_reader :attributes
    attr_reader :destroyed
    attr_reader :new_record
    attr_reader :dynamo_item


    def initialize(attrs={})
      run_callbacks :initialize do
        @attributes = Hash.new
        fields.each do |name, md| 
          write_attribute(name, evaluate_default(md[:default], md[:type]))
          self.class.class_eval "def #{name}; read_attribute('#{name.to_s}'); end"
          self.class.class_eval "def #{name}=(value); write_attribute('#{name.to_s}', value); end"
          self.class.class_eval "def #{name}?; read_attribute('#{name.to_s}').present?; end"
        end
        @dynamo_item = nil
        @destroyed = false
        @new_record = true
        raise UnknownPrimaryKey unless table_hash_key
      end
      attrs &&  attrs.delete_if { |k, v| !fields.has_key?(k) }
      super(attrs)
    end


    def [](attribute)
      read_attribute attribute
    end


    def []=(attribute, value)
      write_attribute attribute, value
    end


    def id
      read_attribute(table_hash_key)
    end


    def id=(value)
      write_attribute(table_hash_key, value)
    end


    def read_attribute_for_validation(key)
      @attributes[key.to_s]
    end


    def read_attribute(attr_name)
      attr_name = attr_name.to_s
      if attr_name == 'id' && fields[table_hash_key] != attr_name.to_sym
        return read_attribute(table_hash_key)
      end
      @attributes[attr_name]   # Type cast!
    end


    def write_attribute(attr_name, value)
      attr_name = attr_name.to_s
      attr_name = table_hash_key.to_s if attr_name == 'id' && fields[table_hash_key]
      if fields.has_key?(attr_name)
        @attributes[attr_name] = type_cast_attribute_for_write(attr_name, value)
      else
        raise ActiveModel::MissingAttributeError, "can't write unknown attribute `#{attr_name}'"
      end
    end


    def to_key
      return nil unless persisted?
      key = respond_to?(:id) && id
      return nil unless key
      table_range_key ? [key, read_attribute(table_range_key)] : [key]
    end


    def assign_attributes(values)
      return if values.blank?
      values = values.stringify_keys
      # if values.respond_to?(:permitted?)
      #   unless values.permitted?
      #     raise ActiveModel::ForbiddenAttributesError
      #   end
      # end
      values.each do |k, v|
        _assign_attribute(k, v)
      end
    end


    def type_cast_attribute_for_write(name, value, metadata=fields[name],
                                      type: metadata[:type])
      case type
      when :string
        return nil if value == nil
        return value.collect(&:to_s) if value.is_a?(Array)
        value
      when :integer
        return nil if value == nil
        return value.collect(&:to_i) if value.is_a?(Array)
        value.to_i
      when :float
        return nil if value == nil
        return value.collect(&:to_f) if value.is_a?(Array)
        value.to_f
      when :boolean
        return nil if value == nil
        return true if value == true
        return true if value == "true"
        false
      when :datetime
        return nil if value == nil || !value.kind_of?(Time)
        value
      when :serialized
        return nil if value == nil
        value
      else
        raise UnsupportedType.new(type.to_s)
      end
    end


    def serialized_attributes
      result = {}
      fields.each do |attribute, metadata|
        serialized = serialize_attribute(attribute, read_attribute(attribute), metadata)
        result[attribute] = serialized unless serialized == nil
      end
      result
    end


    def serialize_attribute(attribute, value, metadata=fields[attribute],
                            type: metadata[:type])
      return nil if value == nil
      case type
      when :string
        ["", []].include?(value) ? nil : value
      when :integer
        value == [] ? nil : value
      when :float
        value == [] ? nil : value
      when :boolean
        value ? "true" : "false"
      when :datetime
        value.to_i
      when :serialized
        value.to_json
      else
        raise UnsupportedType.new(type.to_s)
      end
    end


    def deserialize_attribute(value, metadata, type: metadata[:type])
      case type
      when :string
        return "" if value == nil
        value.is_a?(Set) ? value.to_a : value
      when :integer
        return nil if value == nil
        value.is_a?(Set) || value.is_a?(Array) ? value.collect(&:to_i) : value.to_i
      when :float
        return nil if value == nil
        value.is_a?(Set) || value.is_a?(Array) ? value.collect(&:to_f) : value.to_f
      when :boolean
        case value
        when "true"
          true
        when "false"
          false
        else
          nil
        end
      when :datetime
        return nil if value == nil
        Time.zone.at(value.to_i)
      when :serialized
        return nil if value == nil
        JSON.parse(value)
      else
        raise UnsupportedType.new(type.to_s)
      end
    end


    private

    def _assign_attribute(k, v) # :nodoc:
      public_send("#{k}=", v)
    rescue ActiveModel::NoMethodError
      if respond_to?("#{k}=")
        raise
      else
        raise ActiveModel::UnknownAttributeError, "unknown attribute: #{k}"
      end
    end


    protected

    def evaluate_default(default, type) # :nodoc:
      return default.call if default.is_a?(Proc)
      return "" if default == nil && type == :string
      return default.clone if default.is_a?(Array) || default.is_a?(String)   # Instances need their own copies
      default
    end

  end
end
