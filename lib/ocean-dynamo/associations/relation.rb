module OceanDynamo


  #
  # Relation is a stripped-down version of the corresponding ActiveRecord 
  # class. OceanDynamo doesn't implement scopes or counter caches, which
  # simplifies the code considerably. 
  #
  # Inheritance chain:
  #
  #   Relation             (@klass, @loaded)
  #     CollectionProxy    (@association)
  #
  #
  class Relation

  	attr_reader :klass
  	attr_reader :loaded

  	alias :model :klass
    alias :loaded? :loaded


  	def initialize(klass)
  	  @klass = klass
  	  @loaded = false
  	end


  	def new(*args, &block)
      @klass.new(*args, &block)
    end

    alias build new


  end

end
