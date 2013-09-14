module OceanDynamo
  class Base

    def self.belongs_to(other_class)
      other_class_attr = other_class.to_s.underscore
      name = "#{other_class_attr}_id"
      attribute name, :string, default: nil, pointer: true
      self.class_eval "def #{other_class_attr}; read_pointer('#{name}'); end"
    end

    def read_pointer(name)
      ptr = read_attribute(name)
      return nil if ptr.blank?
      ptr
    end

  end
end
