module OceanDynamo
  module Persistence

    def self.included(base)
      base.extend(ClassMethods)
    end
  

    # ---------------------------------------------------------
    #
    #  Class methods
    #
    # ---------------------------------------------------------

    module ClassMethods

      def create(attributes = nil, &block)
        object = new(attributes)
        yield(object) if block_given?
        object.save
        object
      end


      def create!(attributes = nil, &block)
        object = new(attributes)
        yield(object) if block_given?
        object.save!
        object
      end


      #
      # Class method to delete a record. Returns true if the record existed,
      # false if it didn't.
      #
      def delete(hash, range=nil)
        _late_connect?
        keys = { table_hash_key.to_s => hash }
        keys[table_range_key] = range if table_range_key && range
        options = { key: keys, 
                    return_values: "ALL_OLD"
                  }
        dynamo_table.delete_item(options).attributes ? true : false
      end


      #
      # Deletes all records without instantiating them first.
      #
      def delete_all
        options = {
          consistent_read: true,
          projection_expression: table_hash_key.to_s + (table_range_key ? ", " + table_range_key.to_s : "")
        }
        in_batches :scan, options do |attrs|
          if table_range_key
            delete attrs[table_hash_key.to_s], attrs[table_range_key.to_s]
          else
            delete attrs[table_hash_key.to_s]
          end
        end
        nil
      end


      #
      # Destroys all records after first instantiating them.
      #
      def destroy_all
        in_batches :scan, { consistent_read: true } do |attrs|
          new._setup_from_dynamo(attrs).destroy
        end
        nil
      end


      def _late_connect? # :nodoc:
        return false if table_connected
        return false unless table_connect_policy
        establish_db_connection
        true
      end

    end


    # ---------------------------------------------------------
    #
    #  Instance variables and methods
    #
    # ---------------------------------------------------------

    def initialize(attrs={})
      @destroyed = false
      @new_record = true
      super
    end


    # def dynamo_schema(*)
    #   super
    # end


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
      new_instance = self.class.find(hash_key, range_key, **keywords)
      assign_attributes(new_instance.attributes)
      self
    end


    def touch(name=nil)
      raise DynamoError, "can not touch on a new record object" unless persisted?
      _late_connect?
      run_callbacks :touch do
        begin
          timestamps = set_timestamps(name)
          update_expression = []
          expression_attribute_values = {}
          timestamps.each_with_index do |ts, i|
            nomen = ":ts#{i}"
            expression_attribute_values[nomen] = serialize_attribute(ts, read_attribute(ts))
            update_expression << "#{ts} = #{nomen}"
          end
          update_expression = "SET " + update_expression.join(", ")
          options = { 
              key: serialized_key_attributes,
              update_expression: update_expression
          }.merge(_handle_locking)
          options[:expression_attribute_values] = (options[:expression_attribute_values] || {}).merge(expression_attribute_values)
          dynamo_table.update_item(options)
        rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
          write_attribute(lock_attribute, read_attribute(lock_attribute)-1) unless frozen?
          raise OceanDynamo::StaleObjectError.new(self)
        end
        self
      end
    end


    #
    # Deserialises and assigns all defined attributes. Skips undeclared attributes. 
    # Unlike its predecessor, this version never reads anything from DynamoDB, 
    # it just processes the results from such reads. Thus, the implementation of 
    # +consistent+ reads is up to the caller of this method.
    #    
    def _setup_from_dynamo(arg)
      case arg
      when Aws::DynamoDB::Types::GetItemOutput
        raw_attrs = arg.item
      when Hash
        raw_attrs = arg
      else
        raise ArgumentError, "arg must be an Aws::DynamoDB::Types::GetItemOutput or a Hash (was #{arg.class})"
      end
      dynamo_deserialize_attributes(raw_attrs)
      @new_record = false
      self
    end



    protected

    def _late_connect? # :nodoc:
      self.class._late_connect?
    end


    def dynamo_persist(lock: nil) # :nodoc:
      _late_connect?
      begin
        options = _handle_locking(lock)                       # This might increment an attr...
        options = options.merge(item: serialized_attributes)  # ... which we serialise here.
        dynamo_table.put_item(options)
      rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
        if lock
          write_attribute(lock, read_attribute(lock)-1) unless frozen?
        end
        raise OceanDynamo::StaleObjectError.new(self)
      end
      @new_record = false
      true
    end


    def dynamo_delete(lock: nil) # :nodoc:
      _late_connect?
      begin
        options = { key: serialized_key_attributes }.merge(_handle_locking(lock))
        dynamo_table.delete_item(options)
      rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
        if lock
          write_attribute(lock, read_attribute(lock)-1) unless frozen?
        end
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


    def serialized_key_attributes
      result = Hash.new
      # First the hash key
      attribute = table_hash_key
      metadata = fields[attribute]
      serialized = serialize_attribute(attribute, read_attribute(attribute), metadata)
      raise "Hash key may not be null" if serialized == nil
      result[attribute] = serialized
      # Then the range key, if any
      if table_range_key
        attribute = table_range_key
        metadata = fields[attribute]
        serialized = serialize_attribute(attribute, read_attribute(attribute), metadata)
        raise "Range key may not be null" if serialized == nil
        result[attribute] = serialized
      end
      result
    end


    def serialize_attribute(attribute, value, metadata=fields[attribute],
                            target_class: metadata['target_class'],         # Remove?
                            type: metadata['type'])
      return nil if value == nil
      case type
      when :reference
        value
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


    def dynamo_deserialize_attributes(hash) # :nodoc:
      result = Hash.new
      fields.each do |attribute, metadata|
        next if metadata['no_save']
        result[attribute] = deserialize_attribute(hash[attribute], metadata)
      end
      assign_attributes(result)
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


    #
    # Returns a hash with a condition expression which has to be satisfied 
    # for the write or delete operation to succeed.
    # Note that this method will increment the lock attribute. This means
    # two things:
    #   1. Collect the instance attributes after this method has been called.
    #   2. Remember that care must be taken to decrement the lock attribute in
    #      case the subsequent write/delete operation fails or throws an 
    #      exception, such as +StaleObjectError+.
    #
    def _handle_locking(lock=lock_attribute) # :nodoc:
      _late_connect?
      if lock
        current_v = read_attribute(lock)
        write_attribute(lock, current_v+1) unless frozen?
        { condition_expression: "#{lock} = :cv",
          expression_attribute_values: { ":cv" => current_v }
        }
      else
        {}
      end
    end

  end
end
