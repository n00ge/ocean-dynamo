module OceanDynamo
  module BelongsTo

    def self.included(base)
      base.extend(ClassMethods)
    end
  

    module ClassMethods

      #
      # 
      #
      def belongs_to(target)                             # :master, "master", Master
        target_attr = target.to_s.underscore             # "master"
        target_attr_id = "#{target_attr}_id"             # "master_id"
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
        self.relations[target_class] = :belongs_to


        # Define accessors for instances
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


    protected

    #
    # This is run by #initialize and by #assign_attributes to set the
    # association variables (@master, for instance) and its associated attribute
    # (such as master_id) to the value given.
    #
    def assign_associations(attrs)  # :nodoc: 
      if attrs && attrs.include?(:master)
        @master = attrs[:master]
        write_attribute('master_id', @master)
      end
    end


    def read_and_maybe_load_pointer(name)  # :nodoc:
      ptr = read_attribute(name)
      return nil if ptr.blank?
      if persisted? && ptr.is_a?(String)
        parent = fields[name][:target_class].find(ptr, consistent: true)  # TODO: true?
        write_attribute(name, parent)  # Keep the instance we've just read
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
