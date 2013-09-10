module OceanDynamo
  class Base

    # ---------------------------------------------------------
    #
    #  Class methods
    #
    # ---------------------------------------------------------


    def self.create(attributes = nil, &block)
      object = new(attributes)
      yield(object) if block_given?
      object.save
      object
    end


    def self.create!(attributes = nil, &block)
      object = new(attributes)
      yield(object) if block_given?
      object.save!
      object
    end


    def self.delete(hash, range=nil)
      item = dynamo_items[hash, range]
      return false unless item.exists?
      item.delete
      true
    end


    # ---------------------------------------------------------
    #
    #  Instance variables and methods
    #
    # ---------------------------------------------------------

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


    def deserialized_attributes(consistent_read: false, hash: nil)
      hash ||= dynamo_item.attributes.to_hash(consistent_read: consistent_read)
      result = {}
      fields.each do |attribute, metadata|
        result[attribute] = deserialize_attribute(hash[attribute], metadata)
      end
      result
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
        Time.at(value.to_i)
      when :serialized
        return nil if value == nil
        JSON.parse(value)
      else
        raise UnsupportedType.new(type.to_s)
      end
    end


    def destroyed?
      @destroyed
    end


    def new_record?
      @new_record
    end


    def persisted?
      !(new_record? || destroyed?)
    end


    def valid?(context = nil)
      context ||= (new_record? ? :create : :update)
      output = super(context)
      errors.empty? && output
    end 


    def save
      begin
        create_or_update
      rescue RecordInvalid
        false
      end
    end


    def save!(*)
      create_or_update || raise(RecordNotSaved)
    end


    def update_attributes(attributes={})
      assign_attributes(attributes)
      save
    end


    def update_attributes!(attributes={})
      assign_attributes(attributes)
      save!
    end


    def create_or_update
      result = new_record? ? create : update
      result != false
    end


    def create
      return false unless valid?(:create)
      run_callbacks :commit do
        run_callbacks :save do
          run_callbacks :create do
            k = read_attribute(table_hash_key)
            write_attribute(table_hash_key, SecureRandom.uuid) if k == "" || k == nil
            t = Time.now
            self.created_at ||= t
            self.updated_at ||= t
            dynamo_persist
            true
          end
        end
      end
    end


    def update
      return false unless valid?(:update)
      run_callbacks :commit do
        run_callbacks :save do
          run_callbacks :update do
            self.updated_at = Time.now
            dynamo_persist
            true
          end
        end
      end
    end

    def destroy
      run_callbacks :commit do
        run_callbacks :destroy do
          delete
        end
      end
    end


    def delete
      if persisted?
        @dynamo_item.delete
      end
      @destroyed = true
      #freeze
    end


    def reload(**keywords)
      range_key = table_range_key && attributes[table_range_key]
      new_instance = self.class.find(id, range_key, **keywords)
      assign_attributes(new_instance.attributes)
      self
    end


    def touch(name=nil)
      run_callbacks :touch do
        attrs = [:updated_at]
        attrs << name if name
        t = Time.now
        attrs.each { |k| write_attribute name, t }
        # TODO: handle lock_version
        dynamo_item.attributes.update do |u|
          attrs.each do |k|
            u.set(k => serialize_attribute(k, t))
          end
        end
        self
      end
    end



    protected

    def perform_validations(options={}) # :nodoc:
      options[:validate] == false || valid?(options[:context])
    end


    def dynamo_persist
      @dynamo_item = dynamo_items.put(serialized_attributes)
      @new_record = false
    end


    def post_instantiate(item, consistent)
      @dynamo_item = item
      @new_record = false
      assign_attributes(deserialized_attributes(
        hash: nil,
        consistent_read: consistent)
      )
      self
    end


  end
end
