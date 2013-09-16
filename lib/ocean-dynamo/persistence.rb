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


    def self.delete_all
      dynamo_items.each() do |item|
        item.delete
      end
      nil
    end


    def self.destroy_all
      dynamo_items.select() do |item_data|
        new._setup_from_dynamo(item_data).destroy
      end
      nil
    end


    # ---------------------------------------------------------
    #
    #  Instance variables and methods
    #
    # ---------------------------------------------------------

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


    def save(options={})
      if perform_validations(options)
        begin
          create_or_update
        rescue RecordInvalid
          false
        end
      else
        false
      end
    end


    def save!(options={})
      if perform_validations(options)
        options[:validate] = false
        create_or_update(options) || raise(RecordNotSaved)
      else
        raise RecordInvalid.new(self)
      end
    end


    def update_attributes(attrs={}, options={})
      assign_attributes(attrs, options)
      save
    end


    def update_attributes!(attrs={}, options={})
      assign_attributes(attrs, options)
      save!
    end


    def create_or_update(options={})
      result = new_record? ? create(options) : update(options)
      result != false
    end


    def create(options={})
      return false if options[:validate] != false && !valid?(:create)
      run_callbacks :commit do
        run_callbacks :save do
          run_callbacks :create do
            # Default the correct hash key to a UUID
            if self.class.has_belongs_to?
              write_attribute(table_range_key, SecureRandom.uuid) if range_key.blank?
            else
              write_attribute(table_hash_key, SecureRandom.uuid) if hash_key.blank?
            end

            set_timestamps
            dynamo_persist
            true
          end
        end
      end
    end


    def update(options={})
      return false if options[:validate] != false && !valid?(:update)
      run_callbacks :commit do
        run_callbacks :save do
          run_callbacks :update do
            set_timestamps
            dynamo_persist(lock: lock_attribute)
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


    def destroy!
      destroy || raise(RecordNotDestroyed)
    end


    def delete
      if persisted?
        dynamo_delete(lock: lock_attribute)
      end
      freeze
      @destroyed = true
    end


    def reload(**keywords)
      raise "HELLISHNESS" if id == range_key
      new_instance = self.class.find(hash_key, range_key, **keywords)
      assign_attributes(new_instance.attributes)
      self
    end


    def touch(name=nil)
      raise DynamoError, "can not touch on a new record object" unless persisted?
      _late_connect?
      run_callbacks :touch do
        begin
          dynamo_item.attributes.update(_handle_locking) do |u|
            set_timestamps(name).each do |k|
              u.set(k => serialize_attribute(k, read_attribute(k)))
            end
          end
        rescue AWS::DynamoDB::Errors::ConditionalCheckFailedException
          raise OceanDynamo::StaleObjectError.new(self)
        end
        self
      end
    end


    #
    # Sets the dynamo_item and deserialises and assigns all its defined 
    # attributes. Skips undeclared attributes. 
    #
    # The arg may be either an Item or an ItemData. If Item, a request will be
    # made for the attributes from DynamoDB. If ItemData, no DB access will
    # be made and the existing data will be used.
    #
    # The :consistent keyword may only be used when the arg is an Item.
    #
    def _setup_from_dynamo(arg, consistent: false)
      case arg
      when AWS::DynamoDB::Item
        item = arg
        item_data = nil
      when AWS::DynamoDB::ItemData
        item = arg.item
        item_data = arg
        raise ArgumentError, ":consistent may not be specified when passing an ItemData" if consistent
      else
        raise ArgumentError, "arg must be an AWS::DynamoDB::Item or an AWS::DynamoDB::ItemData"
      end
      
      @dynamo_item = item

      if !item_data
        raw_attrs = item.attributes.to_hash(consistent_read: consistent)
      else
        raw_attrs = item_data.attributes
      end

      dynamo_deserialize_attributes(raw_attrs)
      @new_record = false
      self
    end



    protected

    def self._late_connect? # :nodoc:
      return false if table_connected
      return false unless table_connect_policy
      establish_db_connection
      true
    end


    def _late_connect? # :nodoc:
      self.class._late_connect?
    end


    def dynamo_persist(lock: nil) # :nodoc:
      raise "HELL" if table_hash_key == table_range_key
      if false # self.class.has_belongs_to?
            puts 
            puts "PERSISTING with key [#{table_hash_key}, #{table_range_key}]:"
            puts "  ['#{@attributes[table_hash_key.to_s]}', '#{@attributes[table_range_key.to_s]}']"
            puts
      end
      _late_connect?
      begin
        options = _handle_locking(lock)
        @dynamo_item = dynamo_items.put(serialized_attributes, options)
      rescue AWS::DynamoDB::Errors::ConditionalCheckFailedException
        raise OceanDynamo::StaleObjectError.new(self)
      end
      @new_record = false
      true
    end


    def dynamo_delete(lock: nil) # :nodoc:
      _late_connect?
      begin
        options = _handle_locking(lock)
        @dynamo_item.delete(options)
      rescue AWS::DynamoDB::Errors::ConditionalCheckFailedException
        raise OceanDynamo::StaleObjectError.new(self)
      end
    end


    def serialized_attributes
      result = Hash.new
      fields.each do |attribute, metadata|
        serialized = serialize_attribute(attribute, read_attribute(attribute), metadata)
        result[attribute] = serialized unless serialized == nil
      end
      result
    end


    def dynamo_deserialize_attributes(hash) # :nodoc:
      result = Hash.new
      fields.each do |attribute, metadata|
        next if metadata[:no_save]
        result[attribute] = deserialize_attribute(hash[attribute], metadata)
      end
      assign_attributes(result)
    end


    def serialize_attribute(attribute, value, metadata=fields[attribute],
                            target_class: metadata[:target_class],
                            type: metadata[:type]
                            )
      return nil if value == nil
      #value = value.id if value.kind_of?(target_class)
      case type
      when :reference
        raise DynamoError, ":reference must always have a :target_class" unless target_class
        return value if value.is_a?(String)
        return value.id if value.kind_of?(target_class)
        raise AssociationTypeMismatch, "can't save a #{value.class} in a #{target_class} :reference"
      when :string
        return nil if ["", []].include?(value)
        value
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
      when :reference
        return value
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


    def perform_validations(options={}) # :nodoc:
      options[:validate] == false || valid?(options[:context])
    end


    def set_timestamps(name=nil) # :nodoc:
      attrs = []
      attrs << timestamp_attributes[0] if timestamp_attributes && new_record?
      attrs << timestamp_attributes[1] if timestamp_attributes
      attrs << name if name
      _set_timestamp_attributes(attrs)
      attrs
    end


    def _set_timestamp_attributes(attrs) # :nodoc:
      return if attrs.blank?
      t = Time.zone.now
      attrs.each { |a| write_attribute a, t }
      t
    end


    def _handle_locking(lock=lock_attribute) # :nodoc:
      _late_connect?
      if lock
        current_v = read_attribute(lock)
        write_attribute(lock, current_v+1) unless frozen?
        {if: {lock => current_v}}
      else
        {}
      end
    end

  end
end
