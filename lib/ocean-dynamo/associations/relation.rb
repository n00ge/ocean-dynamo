module OceanDynamo

  class Relation

  	attr_reader :klass
  	attr_reader :values
  	attr_reader :loaded

  	alias :model :klass
    alias :loaded? :loaded


  	def initialize(klass, **values)
  	  @klass = klass
  	  @values = values
  	  @loaded = false
  	end


  	def new(*args, &block)
      @klass.new(*args, &block)
    end

    alias build new


  end

end
