module OceanDynamo
  class Base

    attr_reader :attributes
    attr_reader :destroyed
    attr_reader :new_record
    attr_reader :dynamo_item


    def initialize(attrs={})
      run_callbacks :initialize do
        @attributes = HashWithIndifferentAccess.new
        fields.each do |name, md| 
          write_attribute(name, evaluate_default(md[:default], md[:type]))
          self.class.class_eval "def #{name}; read_attribute('#{name}'); end"
          self.class.class_eval "def #{name}=(value); write_attribute('#{name}', value); end"
          if fields[name][:type] == :boolean
            self.class.class_eval "def #{name}?; read_attribute('#{name}'); end"
          end
        end
        @dynamo_item = nil
        @destroyed = false
        @new_record = true
        raise UnknownPrimaryKey unless table_hash_key
      end
      attrs &&  attrs.delete_if { |k, v| !fields.has_key?(k) }
      super(attrs)
    end


    def read_attribute_for_validation(key)
      @attributes[key]
    end


    def read_attribute(key)
      @attributes[key]
    end


    def write_attribute(key, value)
      @attributes[key] = value
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


    def to_key
      return nil unless persisted?
      key = respond_to?(:id) && id
      return nil unless key
      table_range_key ? [key, read_attribute(table_range_key)] : [key]
    end


    def assign_attributes(values)
      # if values.respond_to?(:permitted?)
      #   unless values.permitted?
      #     raise ActiveModel::ForbiddenAttributesError
      #   end
      # end
      values.each do |k, v|
        send("#{k}=", v)
      end
    end


    protected

    def evaluate_default(default, type)
      return default.call if default.is_a?(Proc)
      return "" if default == nil && type == :string
      return default.clone if default.is_a?(Array) || default.is_a?(String)   # Instances need their own copies
      default
    end

  end
end
