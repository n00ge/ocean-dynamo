module OceanDynamo
  module HasMany

    def self.included(base)
      base.extend(ClassMethods)
    end
  

    # ---------------------------------------------------------
    #
    #  Class methods
    #
    # ---------------------------------------------------------

    module ClassMethods

      #
      #
      #
      def has_many(children)                                         # :children
        children_attr = children.to_s.underscore                     # "children"
        child_class = children_attr.singularize.camelize.constantize # Child
        register_relation(child_class, :has_many)
        # Define accessors for instances
        self.class_eval "def #{children_attr}; read_children(#{child_class}); end"
        self.class_eval "def #{children_attr}=(value); write_children(#{child_class}, value); end"
        # TODO: "?" method
      end

    end


    # ---------------------------------------------------------
    #
    #  Instance variables and methods
    #
    # ---------------------------------------------------------

    #
    #
    #
    def read_children(child_class)
      if new_record? 
        nil
      else
        result = Array.new
        _late_connect?
        child_items = child_class.dynamo_items
        child_items.query(hash_value: id, range_gte: "0") do |item_data|
          result << child_class.new._setup_from_dynamo(item_data)
        end
        result
      end
    end

    #
    #
    #
    def write_children(child_class, value)
      return nil if value.blank?
      raise AssociationTypeMismatch, "not an array or nil" if !value.is_a?(Array)
      raise AssociationTypeMismatch, "an array element is not a #{child_class}" unless value.all? { |m| m.is_a?(child_class) }
      # We now know that value is an array containing only members of the child_class
      value.each(&:save!)
      value
    end

  end
end
