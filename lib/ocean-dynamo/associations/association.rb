module OceanDynamo
  module Associations
    #
    #   Association
    #     CollectionAssociation
    #       HasAndBelongsToManyAssociation
    #       HasManyAssociation
    #
    class Association #:nodoc:

      attr_reader :owner
      attr_reader :reflection
      attr_reader :target


      def initialize(owner, reflection)
        @owner, @reflection = owner, reflection
        reset
      end


      #
      # Returns the class of the target. belongs_to polymorphic overrides this to look at the
      # polymorphic_type field on the owner.
      #
      def klass
        reflection.klass
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
      # It's up to subclasses to implement the stale_state method if relevant.
      #
      def stale_state
        nil
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
        def foreign_key_present?
          false
        end

    end
  end
end
