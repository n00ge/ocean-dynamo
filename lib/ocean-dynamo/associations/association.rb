module OceanDynamo
  module Associations
    #
    # This is the root class of all Associations.
    # The class structure is exactly like in ActiveRecord:
    #
    #   Association
    #     CollectionAssociation
    #       HasAndBelongsToManyAssociation
    #       HasManyAssociation
    #
    # It should be noted, however, that the ActiveRecord documentation  
    # is misleading: belongs_to and has_one no longer are implemented using
    # proxies, even though the documentation and the source itself says it is.
    # Furthermore, method_missing is no longer used at all, despite what the
    # documentation and source comments say.
    #
    # In OceanDynamo, we have removed the unused classes and stripped away
    # the SQL-specific features such as scopes. Neither do we implement counter
    # caches. We have kept the same module and class structure for compatibility, 
    # though.
    #
    class Association #:nodoc:

      attr_reader :owner
      attr_reader :reflection
      attr_reader :target


      #
      # 
      #
      def initialize(owner, reflection)
        @owner, @reflection = owner, reflection
        reset
      end

      #
      # Resets the \loaded flag to +false+ and sets the \target to +nil+.
      #
      def reset
        @loaded = false
        @target = nil
        @stale_state = nil
      end

      #
      # Has the \target been already \loaded?
      #
      def loaded?
        @loaded
      end

      #
      # Asserts the \target has been loaded setting the \loaded flag to +true+.
      #
      def loaded!
        @loaded = true
        @stale_state = stale_state
      end

      #
      # Sets the target of this association to <tt>\target</tt>, and the \loaded flag to +true+.
      #
      def target=(target)
        @target = target
        loaded!
      end

      #
      # The target is stale if the target no longer points to the record(s) that the
      # relevant foreign_key(s) refers to. If stale, the association accessor method
      # on the owner will reload the target. It's up to subclasses to implement the
      # stale_state method if relevant.
      #
      # Note that if the target has not been loaded, it is not considered stale.
      #
      def stale_target?
        loaded? && @stale_state != stale_state
      end

      #
      # Loads the \target if needed and returns it.
      #
      # This method is abstract in the sense that it relies on +find_target+,
      # which is expected to be provided by descendants.
      #
      # If the \target is already \loaded it is just returned. Thus, you can call
      # +load_target+ unconditionally to get the \target.
      #
      # ActiveRecord::RecordNotFound is rescued within the method, and it is
      # not reraised. The proxy is \reset and +nil+ is the return value.
      #
      def load_target
        @target = find_target if (@stale_state && stale_target?) || find_target?
        loaded! unless loaded?
        target
      rescue OceanDynamo::RecordNotFound
        reset
      end

      #
      # Returns the class of the target. belongs_to polymorphic used to override this 
      # to look at the polymorphic_type field on the owner. However, belongs_to is no
      # longer implemented in AR using an Assocation, so we keep this only for structural
      # compatibility.
      #
      def klass
        reflection.klass
      end

      #
      # Reloads the \target and returns +self+ on success.
      #
      def reload
        reset
        load_target
        self unless target.nil?
      end


      private

        def find_target?
          !loaded? && (!owner.new_record? || foreign_key_present?) && klass
        end

        #
        # Should be true if there is a foreign key present on the owner which
        # references the target. This is used to determine whether we can load
        # the target if the owner is currently a new record (and therefore
        # without a key).
        #
        # Currently implemented by belongs_to (vanilla and polymorphic) and
        # has_one/has_many :through associations which go through a belongs_to
        #
        # This method is, nowadays, merely an archaeological artifact since
        # +belongs_to+ no longer uses Associations, meaning this method will
        # never be overridden.
        #
        def foreign_key_present?
          false
        end

        #
        # This should be implemented to return the values of the relevant key(s) on the owner,
        # so that when stale_state is different from the value stored on the last find_target,
        # the target is stale.
        #
        # This is only relevant to certain associations, which is why it returns nil by default.
        #
        def stale_state
          nil
        end

    end
  end
end
