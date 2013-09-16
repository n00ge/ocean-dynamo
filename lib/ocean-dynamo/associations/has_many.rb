module OceanDynamo
  class Base

    def self.has_many(children)                                    # :children
      children_attr = children.to_s.underscore                     # "children"
      child_class = children_attr.singularize.camelize.constantize # Child
      self.relations[child_class] = :has_many

      # Define accessors for instances
      self.class_eval "def #{children_attr}; read_children('#{children_attr}'); end"
      self.class_eval "def #{children_attr}=(value); write_children('#{children_attr}', value); end"
      # TODO: "?" method
    end


    def self.relates_to(klass)
      relations[klass]
    end


    def read_children(children_attr)
      if new_record? 
        nil
      else
        Array.new
      end
    end


    def write_children(children_attr, children)
      children
    end


  end
end
