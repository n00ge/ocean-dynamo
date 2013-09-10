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
        create_or_update || raise(RecordNotSaved)
      else
        raise RecordInvalid
      end
    end


    def update_attributes(attrs={})
      assign_attributes(attrs)
      save
    end


    def update_attributes!(attrs={})
      assign_attributes(attrs)
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
            t = Time.zone.now
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
            self.updated_at = Time.zone.now
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


    def destroy!
      destroy || raise(RecordNotDestroyed)
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
      raise DynamoError, "can not touch on a new record object" unless persisted?
      run_callbacks :touch do
        attrs = ['updated_at']
        attrs << name if name
        t = Time.zone.now
        attrs.each { |k| write_attribute k, t }
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
