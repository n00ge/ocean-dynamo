module OceanDynamo
  class Base

    def self.has_many(children)                                    # :children
      children_attr = children.to_s.underscore                     # "children"
      child_class = children_attr.singularize.camelize.constantize # Child
      self.relations[child_class] = :has_many
      # Define accessors for instances
      self.class_eval "def #{children_attr}; read_children(#{child_class}); end"
      self.class_eval "def #{children_attr}=(value); write_children('#{children_attr}', value); end"
      # TODO: "?" method
    end


    def self.relates_to(klass)
      relations[klass]
    end


    def read_children(child_class)
      if new_record? 
        nil
      else
        result = Array.new
        _late_connect?
        child_items = child_class.dynamo_items
        child_items.query(hash_value: id, 
                          range_greater_than: "0"
                         ) do |item_data|
          result << child_class.new._setup_from_dynamo(item_data)
        end
        result
      end
    end


    def write_children(children_attr, children_value)
      children_value
    end

  end
end
