module OceanDynamo
  class Base

    def self.belongs_to(target_class)
      target_class = target_class.to_s             # "api_user" or "ApiUser"
      target_attr = target_class.underscore        # "api_user"
      target_attr_id = "#{target_attr}_id"         # "api_user_id"
      target_class = target_class.camelize.constantize    # ApiUser
      attribute target_attr_id, :reference, default: nil, target_class: target_class
      attribute target_attr,    :reference, default: nil, target_class: target_class, no_save: true

      self.class_eval "def #{target_attr}
                         read_and_maybe_load_pointer('#{target_attr_id}')
                       end"

      self.class_eval "def #{target_attr}=(value) 
                         write_attribute('#{target_attr_id}', value) 
                         write_attribute('#{target_attr}', value)
                       end"

      self.class_eval "def #{target_attr_id}
                         read_pointer_id('#{target_attr}')
                       end"

      self.class_eval "def #{target_attr_id}=(value)
                         write_attribute('#{target_attr_id}', value) 
                         write_attribute('#{target_attr}', value)
                       end"
      # TODO: "?" methods
    end


    protected

    def read_and_maybe_load_pointer(name)  # :nodoc:
      ptr = read_attribute(name)
      return nil if ptr.blank?
      if persisted? && ptr.is_a?(String)
        write_attribute(name, fields[name][:target_class].find(ptr))  # Keep the instance we've just read
      else
        ptr
      end
    end

    def read_pointer_id(name)  # :nodoc:
      ptr = read_attribute(name)
      return nil if ptr.blank?
      ptr.is_a?(String) ? ptr : ptr.id
    end

  end
end
