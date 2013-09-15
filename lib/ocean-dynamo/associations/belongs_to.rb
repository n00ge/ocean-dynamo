module OceanDynamo
  class Base

    def self.belongs_to(target)                        # :api_user, "api_user", ApiUser
      target_attr = target.to_s.underscore             # "api_user"
      target_attr_id = "#{target_attr}_id"             # "api_user_id"
      target_class = target_attr.camelize.constantize  # ApiUser
      attribute target_attr_id, :reference, default: nil, target_class: target_class
      #attribute target_attr,    :reference, default: nil, target_class: target_class, no_save: true
      attr_accessor target_attr

      self.class_eval "def #{target_attr}
                         read_and_maybe_load_pointer('#{target_attr_id}')
                       end"

      self.class_eval "def #{target_attr}=(value) 
                         write_attribute('#{target_attr_id}', value) 
                         @#{target_attr} = value
                       end"

      self.class_eval "def #{target_attr_id}
                         get_pointer_id(@#{target_attr})
                       end"

      self.class_eval "def #{target_attr_id}=(value)
                         write_attribute('#{target_attr_id}', value) 
                         @#{target_attr} = value
                       end"
      # TODO: "?" methods
    end



    protected

    #
    # This is run by #initialize and by #assign_attributes to set the
    # association variables (@master, for instance) and its associated attribute
    # (such as master_id) to the value given.
    #
    def assign_associations(attrs)  # :nodoc: 
      if attrs && attrs.include?(:master)
        #attrs = attrs.stringify_keys
        @master = attrs[:master]
        write_attribute('master_id', @master)
      end
    end


    def read_and_maybe_load_pointer(name)  # :nodoc:
      ptr = read_attribute(name)
      return nil if ptr.blank?
      if persisted? && ptr.is_a?(String)
        write_attribute(name, fields[name][:target_class].find(ptr))  # Keep the instance we've just read
      else
        ptr
      end
    end

    def get_pointer_id(ptr)  # :nodoc:
      return nil if ptr.blank?
      ptr.is_a?(String) ? ptr : ptr.id
    end

  end
end
