module OceanDynamo
  module Associations
    #
    # Collection proxies in OceanDynamo are middlemen between the object that
    # holds the association, known as the <tt>@owner</tt>, and the actual associated
    # object, known as the <tt>@target</tt>. The kind of association any proxy is
    # about is available in <tt>@reflection</tt>. That's an instance of the class
    # OceanDynamo::Reflection::AssociationReflection.
    #
    # For example, given
    #
    #   class Blog < OceanDynamo::Table
    #     has_many :posts
    #   end
    #
    #   blog = Blog.first
    #
    # the collection proxy in <tt>blog.posts</tt> has the object in +blog+ as
    # <tt>@owner</tt>, the collection of its posts as <tt>@target</tt>, and
    # the <tt>@reflection</tt> object represents a <tt>:has_many</tt> macro.
    #
    # This class delegates unknown methods to <tt>@target</tt> through explicit 
    # proxy methods for each separate operation.
    #
    # The <tt>@target</tt> object is not \loaded until needed. As it turns out,
    # the key to this lazy loading scheme is <tt>to_ary</tt>.
    #
    #
    # Inheritance chain:
    #
    #   Relation             (@klass, @loaded)
    #     CollectionProxy    (@association)
    #



    class CollectionProxy < Relation


      def initialize(klass, association)
        @association = association
        super klass
      end


      def proxy_association
        @association
      end


      def target
        @association.target
      end


      def load_target
        @association.load_target
      end


      def loaded?
        @association.loaded?
      end


      def select(select = nil, &block)
        @association.select(select, &block)
      end


      def find(*args, &block)
        @association.find(*args, &block)
      end


      def first(*args)
        @association.first(*args)
      end


      def last(*args)
        @association.last(*args)
      end


      def build(attributes = {}, &block)
        @association.build(attributes, &block)
      end
      alias_method :new, :build


      def create(attributes = {}, &block)
        @association.create(attributes, &block)
      end


      def create!(attributes = {}, &block)
        @association.create!(attributes, &block)
      end


      def concat(*records)
        @association.concat(*records)
      end


      def replace(other_array)
        @association.replace(other_array)
      end


      def delete_all
        @association.delete_all
      end


      def clear
        delete_all
        self
      end


      def destroy_all
        @association.destroy_all
      end


      def delete(*records)
        @association.delete(*records)
      end


      def destroy(*records)
        @association.destroy(*records)
      end


      def distinct
        @association.distinct
      end
      alias uniq distinct


      def count(column_name = nil, options = {})
        @association.count(column_name, options)
      end


      def size
        @association.size
      end


      def length
        @association.length
      end


      def empty?
        @association.empty?
      end


      def any?(&block)
        @association.any?(&block)
      end


      def many?(&block)
        @association.many?(&block)
      end


      def include?(record)
        @association.include?(record)
      end


      def ==(other)
        load_target == other
      end


      def to_ary
        load_target.dup
      end
      alias_method :to_a, :to_ary


      def <<(*records)
        proxy_association.concat(records) && self
      end
      alias_method :push, :<<
      alias_method :append, :<<


      def prepend(*args)
        raise NoMethodError, "prepend on association is not defined. Please use << or append"
      end


      def reload
        proxy_association.reload
        self
      end


    end
  end
end
