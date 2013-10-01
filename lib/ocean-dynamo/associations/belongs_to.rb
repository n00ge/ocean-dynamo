module OceanDynamo
  module BelongsTo

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
      # Class macro to define the +belongs_to+ relation.
      #
      def belongs_to(target)                             # :master, "master", Master
        target_attr = target.to_s.underscore             # "master"
        target_attr_id = "#{target_attr}_id"             # "master_id"
        class_name = target_attr.classify                # "Master"
        define_class_if_not_defined(class_name)
        target_class = target_attr.camelize.constantize  # Master

        assert_only_one_belongs_to!

        self.table_range_key = table_hash_key            # The RANGE KEY is variable
        self.table_hash_key = target_attr_id.to_sym      # The HASH KEY is the parent UUID

        attribute table_hash_key, :string                # Define :master_id
        define_attribute_accessors(table_hash_key)       # Define master_id, master_id=, master_id?

        # Make sure there always is a parent
        validates(table_hash_key, presence: true)        # Can't save without a parent_id

        # Define the range attribute (our unique UUID)
        attribute(table_range_key, :string, default: "") # Define :uuid
        define_attribute_accessors(table_range_key)      # define uuid, uuid=, uuid?



        # Define the parent id attribute 
        attribute target_attr_id, :reference, default: nil, target_class: target_class,
                                  association: :belongs_to
        register_relation(target_class, :belongs_to)


        # Define accessors for instances
        self.class_eval "def #{target_attr}
                           @#{target_attr} ||= load_target_from_id('#{target_attr_id}')
                         end"

        self.class_eval "def #{target_attr_id}
                           read_attribute('#{target_attr_id}')
                         end"

        self.class_eval "def #{target_attr}=(value) 
                           target, target_id = type_check_target(#{target_class}, value)
                           write_attribute('#{target_attr_id}', target_id) 
                           @#{target_attr} = target
                           value
                         end"

        self.class_eval "def #{target_attr_id}=(value)
                           type_check_foreign_key('#{target_attr_id}', value)
                           write_attribute('#{target_attr_id}', value) 
                           @#{target_attr} = nil
                           value
                         end"
      end


      #
      # Returns true if the class has a belongs_to association.
      #
      def has_belongs_to?
        fields[table_hash_key]['association'] == :belongs_to
      end



      #
      # Returns the class of the belongs_to association, or false if none.
      #
      def belongs_to_class
        has_belongs_to? && fields[table_hash_key]['target_class']
      end



      protected

      #
      # belongs_to can be specified only once in each model, since we use the range key to
      # store its UUID and the hash key to store the UUID of the parent, as in
      # ["parent_uuid", "child_uuid"]. This allows the parent to find all its children 
      # extremely efficiently by using only the primary index. It also allows the child
      # to find its parent using only its own hash key. Presto: scalability without any
      # secondary indices in the has_many/belongs_to association.
      #
      # Caveat: the parent must have a simple primary key, not a composite one. It *is*
      # possible to use a composite key, but then the children must use scans to find
      # their parents. We could conditionalise this, of course, so that the lookup
      # strategy is transparent to the user.
      #
      def assert_only_one_belongs_to!  # :nodoc:
        if has_belongs_to?
          raise OceanDynamo::AssociationMustBeUnique, 
                "#{self} already belongs_to #{belongs_to_class}" 
        end
        false
      end
    end


    # ---------------------------------------------------------
    #
    #  Instance variables and methods
    #
    # ---------------------------------------------------------
    # def initialize(attrs={})
    #   super
    # end



    #
    # This is run by #initialize and by #assign_attributes to set the
    # association instance variables (@master, for instance) and their associated 
    # attributes (such as master_id) from one single given value such as :master 
    # and :master_id.
    #
    def set_belongs_to_association(attrs)  # :nodoc:
      parent_class = self.class.belongs_to_class
      return unless parent_class
      parent_class = parent_class.to_s.underscore.to_sym
      send("#{parent_class}=", attrs[parent_class]) if attrs && attrs.include?(parent_class)
    end


    def load_target_from_id(name)  # :nodoc:
      v = read_attribute(name)
      return nil unless v
      fields[name][:target_class].find(v, consistent: true)
    end


    def type_check_foreign_key(name, value)
      return unless value
      return if value.is_a?(String)
      raise AssociationTypeMismatch, "Foreign key #{name} must be nil or a string"
    end


    def type_check_target(target_class, value)
      return nil unless value
      return [value, value.hash_key] if value.kind_of?(target_class)
      raise AssociationTypeMismatch, "can't save a #{value.class} in a #{target_class} foreign key"
    end

  end
end
