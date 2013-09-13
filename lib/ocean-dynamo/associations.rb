module OceanDynamo
  class Base

    def self.belongs_to(other_class)
      other_class_attr = other_class.to_s.underscore
      attribute "#{other_class_attr}_id", :string, default: ""
      self.class_eval "def #{other_class_attr}; nil; end"
    end

  end
end
