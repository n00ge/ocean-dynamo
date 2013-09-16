module OceanDynamo
  module Associations

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
      def relates_to(klass)
        relations[klass]
      end

      #
      #
      #
      def register_relation(klass, value)
        relations[klass] = value
      end

      #
      #
      #
      def clear_relations
        self.relations = Hash.new
      end


      def dynamo_schema(*)
        clear_relations
        super
      end

    end


    # ---------------------------------------------------------
    #
    #  Instance variables and methods
    #
    # ---------------------------------------------------------

    # def initialize(*)
    #   self.class.clear_relations
    # end

  end
end
