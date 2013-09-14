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
            k = read_attribute(table_hash_key)
            write_attribute(table_hash_key, SecureRandom.uuid) if k == "" || k == nil
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
      range_key = table_range_key && attributes[table_range_key]
      new_instance = self.class.find(id, range_key, **keywords)
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


    def perform_validations(options={}) # :nodoc:
      options[:validate] == false || valid?(options[:context])
    end


    def dynamo_persist(lock: nil) # :nodoc:
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


    def dynamo_unpersist(item, consistent) # :nodoc:
      _late_connect?
      @dynamo_item = item
      @new_record = false
      assign_attributes(_dynamo_read_attributes(consistent_read: consistent))
      self
    end


    def _dynamo_read_attributes(consistent_read: false) # :nodoc:
      hash = _dynamo_read_raw_attributes(consistent_read)
      result = Hash.new
      fields.each do |attribute, metadata|
        next if metadata[:no_save]
        result[attribute] = deserialize_attribute(hash[attribute], metadata)
      end
      result
    end


    def _dynamo_read_raw_attributes(consistent) # :nodoc:
      dynamo_item.attributes.to_hash(consistent_read: consistent)
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
