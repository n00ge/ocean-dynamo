module OceanDynamo
  module Basal
      
    #
    # The equality comparator. 
    #
    def ==(comparison_object)
      super ||
        comparison_object.instance_of?(self.class) &&
        id.present? &&
        comparison_object.id == id
    end
    alias :eql? :==


    #
    # Allows sort on instances
    #
    def <=>(other_object)
      if other_object.is_a?(self.class)
        self.to_key <=> other_object.to_key
      end
    end


    #
    # Clone and freeze the attributes hash such that associations are still
    # accessible, even on destroyed records, but cloned models will not be
    # frozen.
    #
    def freeze
      @attributes = @attributes.clone.freeze
      self
    end


    #
    # Returns +true+ if the attributes hash has been frozen.
    #
    def frozen?
      @attributes.frozen?
    end

  end
end
