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
      # Defines a has_many relation to a belongs_to class.
      #
      def has_many(children)                                         # :children
        children_attr = children.to_s.underscore                     # "children"
        child_class = children_attr.singularize.camelize.constantize # Child
        register_relation(child_class, :has_many)
        # Define accessors for instances
        self.class_eval "def #{children_attr} 
                           @#{children_attr} ||= read_children(#{child_class})
                         end"
        self.class_eval "def #{children_attr}=(value)
                           @#{children_attr} = value
                         end"
        self.class_eval "def #{children_attr}? 
                           @#{children_attr} ||= read_children(#{child_class})
                           @#{children_attr}.present?
                         end"
      end

    end


    # ---------------------------------------------------------
    #
    #  Instance variables and methods
    #
    # ---------------------------------------------------------


    #
    # Reads all children of a has_many relation.
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
    # Write all children in the arg, which should be nil or an array.
    #
    def write_children(child_class, arg)
      return nil if arg.blank?
      raise AssociationTypeMismatch, "not an array or nil" if !arg.is_a?(Array)
      raise AssociationTypeMismatch, "an array element is not a #{child_class}" unless arg.all? { |m| m.is_a?(child_class) }
      # We now know that arg is an array containing only members of the child_class
      arg.each(&:save!)
      arg
    end


    #
    # Sets all has_many relations to nil.
    #
    def reload(*)
      result = super

      self.class.relations_of_type(:has_many).each do |klass|
        attr_name = klass.to_s.pluralize.underscore
        instance_variable_set("@#{attr_name}", nil)
      end

      result
    end


    protected

    #
    # This version also writes back any relations. TODO: only
    # dirty relations should be persisted. Introduce a dirty flag.
    # Easiest done via an association proxy object.
    #
    def dynamo_persist(*)  # :nodoc:
      result = super

      self.class.relations_of_type(:has_many).each do |klass|
        attr_name = klass.to_s.pluralize.underscore
        # First create or update the children in the new set
        new_children = instance_variable_get("@#{attr_name}") || []
        write_children klass, new_children
        # Destroy all children not in the new set (this is not yet scalable)
        read_children(klass).each do |c|
          next if new_children.include?(c)
          c.delete
        end
      end

      result
    end

  end
end
