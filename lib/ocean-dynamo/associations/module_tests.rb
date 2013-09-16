module One
  def initialize(*args)
    puts "We're in One#initialize, next: super"
    super
    puts "We're in One#initialize, back from super"
  end

  def foo
    [1, 2, 3]
  end
end

# --------------------------------------------------------------------------

module Two
  def initialize(*args)
    puts "We're in Two#initialize, next: super"
    super
    puts "We're in Two#initialize, back from super"
  end

  def foo
    super + [:two, :two]
  end
end

# --------------------------------------------------------------------------

module Three
  def initialize(*args)
    puts "We're in Three#initialize, next: super"
    super
    puts "We're in Three#initialize, back from super"
  end

  def foo
    super + ["3"]
  end
end

# --------------------------------------------------------------------------

module Od

  class Base
    def initialize(*args)
      puts "We're in Base#initialize, next: super"
      super
      puts "We're in Base#initialize, back from super"
    end

    def foo
      super << :novus
    end
  end

end

# --------------------------------------------------------------------------

module Od
  class Base
    include One
    include Two
    include Three
  end
end


# i = Od::Base.new =>
# We're in Base#initialize, next: super
# We're in Three#initialize, next: super
# We're in Two#initialize, next: super
# We're in One#initialize, next: super
# We're in One#initialize, back from super
# We're in Two#initialize, back from super
# We're in Three#initialize, back from super
# We're in Base#initialize, back from super

# i.foo
# => [1, 2, 3, :two, :two, "3", :novus]
