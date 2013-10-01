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
      # Class macro to define the +belongs_to+ relation. For example:
      #
      #  class Forum < OceanDynamo::Table
      #    dynamo_schema do
      #      attribute :name
      #      attribute :description
      #    end
      #    has_many :topics, dependent: :destroy
      #  end
      # 
      # class Topic < OceanDynamo::Table
      #   dynamo_schema(:uuid) do
      #     attribute :title
      #   end
      #   belongs_to :forum
      #   has_many :posts, dependent: :destroy
      # end
      # 
      # class Post < OceanDynamo::Table
      #   dynamo_schema(:uuid) do
      #     attribute :body
      #   end
      #   belongs_to :topic, composite_key: true
      # end
      # 
      # The only non-standard aspect of the above is <tt>composite_key: true</tt>, 
      # which is required as the Topic class itself has a +belongs_to+ relation and 
      # thus has a composite key. This must be declared in the child class as it 
      # needs to know how to retrieve its parent. If you were to add a Comment class
      # to the above with a <tt>has_many/belongs_to</tt> relation to Post, the Comment
      # class would also have a <tt>belongs_to :post, composite_key: true</tt> statement,
      # since Post already has a composite key due to its +belongs_to+ relation to
      # the Topic class.
      #
      def belongs_to(target, composite_key: false)       # :master, "master", Master
        target_attr = target.to_s.underscore             # "master"
        target_attr_id = "#{target_attr}_id"             # "master_id"
        class_name = target_attr.classify                # "Master"
        define_class_if_not_defined(class_name)
        target_class = class_name.constantize            # Master

        assert_only_one_belongs_to!
        assert_range_key_not_specified!
        assert_hash_key_is_not_id!

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
                           @#{target_attr} ||= load_target_from_id('#{target_attr_id}', #{composite_key})
                         end"

        self.class_eval "def #{target_attr_id}
                           read_attribute('#{target_attr_id}')
                         end"

        self.class_eval "def #{target_attr}=(value) 
                           target, target_id = type_check_target(#{target_class}, value, #{composite_key})
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


      #
      # Make sure the range key isn't specified.
      #
      def assert_range_key_not_specified!  # :nodoc:
        raise RangeKeyMustNotBeSpecified, 
              "Tables with belongs_to relations may not specify the range key" if table_range_key
      end


      #
      # Make sure the hash key isn't called :id.
      #
      def assert_hash_key_is_not_id!  # :nodoc:
        raise HashKeyMayNotBeNamedId, 
              "Tables with belongs_to relations may not name their hash key :id" if table_hash_key.to_s == "id"
      end
    end


    # ---------------------------------------------------------
    #
    #  Instance variables and methods
    #
    # ---------------------------------------------------------

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


    def load_target_from_id(name, composite_key)  # :nodoc:
      v = read_attribute(name)
      return nil unless v
      h, r = composite_key ? v.split(':') : v
      fields[name][:target_class].find(h, r, consistent: true)
    end


    def type_check_foreign_key(name, value)
      return unless value
      return if value.is_a?(String)
      raise AssociationTypeMismatch, "Foreign key #{name} must be nil or a string"
    end


    def type_check_target(target_class, value, composite_key)
      return nil unless value
      if value.kind_of?(target_class)
        foreign_key = value.hash_key
        foreign_key += ':' + value.range_key if composite_key
        return [value, foreign_key]
      else
        raise AssociationTypeMismatch, "can't save a #{value.class} in a #{target_class} foreign key"
      end
    end

  end
end
