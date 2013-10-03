module OceanDynamo
  module Associations

    def self.included(base)
      base.extend(ClassMethods)
    end

    # This class really does some of the stuff that in ActiveRecord is
    # handled by the Reflection class. We could switch to the AR paradigm
    # at some point.
  

    # ---------------------------------------------------------
    #
    #  Class methods
    #
    # ---------------------------------------------------------

    module ClassMethods

      #
      #
      #
      def relations_of_type(rel_type)
        relations.inject([]) do |acc, rel|
          kl, type = rel
          acc << kl if type == rel_type
          acc
        end
      end

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


      def define_class_if_not_defined(class_name)
        Object.const_set(class_name, Class.new(OceanDynamo::Table)) unless const_defined?(class_name)
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
