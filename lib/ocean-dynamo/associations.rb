module OceanDynamo
  class Base

    def self.belongs_to(other_class)
      klass = other_class.to_s.capitalize.constantize
      other_class_attr = other_class.to_s.underscore
      name = "#{other_class_attr}_id"
      attribute name,             :reference, default: nil, target_class: klass
      attribute other_class_attr, :reference, default: nil, target_class: klass, no_save: true

      self.class_eval "def #{other_class_attr}
                         read_and_maybe_load_pointer('#{name}')
                       end"

      self.class_eval "def #{name}
                         read_pointer_id('#{name}')
                       end"

      self.class_eval "def #{other_class_attr}=(value) 
                         write_attribute('#{name}', value) 
                         write_attribute('#{other_class_attr}', value)
                       end"

      self.class_eval "def #{name}=(value)
                         write_attribute('#{name}', value) 
                         write_attribute('#{other_class_attr}', value)
                       end"
      # TODO: Additional "?" method for name
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
      if ptr.is_a?(String)
        return ptr
      else
        return ptr.id
      end
    end

  end
end
