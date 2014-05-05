require 'spec_helper'

#
# Relation             (@klass, @loaded)
#   CollectionProxy    (@association)
#

class Target < OceanDynamo::Table
  dynamo_schema(create: true, table_name_suffix: Api.basename_suffix) do
    attribute :name
  end
end


module OceanDynamo
  module Associations

    describe CollectionProxy do

      before :each do
        @a = double()
        @cp = CollectionProxy.new(Target, @a)
      end


      it "should inherit from Relation" do
        @cp.should be_a Relation
      end

      it "should set @association to the second argument" do
        @cp.instance_variable_get(:@association).should == @a
      end

      it "should define proxy_association to retrieve @association" do
        @cp.proxy_association.should == @a
      end


      describe "should let @association handle" do

        it "target" do
          @a.should_receive(:target)
          @cp.target
        end

        it "load_target" do
          @a.should_receive(:load_target)
          @cp.load_target
        end

        it "loaded?" do
          @a.should_receive(:loaded?)
          @cp.loaded?
        end

        it "select" do
          @a.should_receive(:select)
          @cp.select
        end

        it "find" do
          @a.should_receive(:find)
          @cp.find
        end

        it "first" do
          @a.should_receive(:first)
          @cp.first
        end

        it "last" do
          @a.should_receive(:last)
          @cp.last
        end

        it "build" do
          @a.should_receive(:build)
          @cp.build
        end

        it "new (as an alias for build)" do
          @a.should_receive(:build)
          @cp.new
        end

        it "create" do
          @a.should_receive(:create)
          @cp.create
        end

        it "create!" do
          @a.should_receive(:create!)
          @cp.create!
        end

        it "concat" do
          @a.should_receive(:concat)
          @cp.concat
        end

        it "replace" do
          @a.should_receive(:replace)
          @cp.replace([double, double, double])
        end

        it "delete_all" do
          @a.should_receive(:delete_all)
          @cp.delete_all
        end

        it "should define clear as delete_all returning self" do
          @a.should_receive(:load_target).twice.and_return([double])
          @a.should_receive(:delete_all)
          @cp.clear.should == @cp
        end

        it "destroy_all" do
          @a.should_receive(:destroy_all)
          @cp.destroy_all
        end

        it "delete" do
          @a.should_receive(:delete)
          @cp.delete
        end

        it "destroy" do
          @a.should_receive(:destroy)
          @cp.destroy
        end

        it "distinct" do
          @a.should_receive(:distinct)
          @cp.distinct
        end

        it "uniq (as an alias for distinct)" do
          @a.should_receive(:distinct)
          @cp.uniq
        end

        it "count" do
          @a.should_receive(:count)
          @cp.count
        end

        it "size" do
          @a.should_receive(:size)
          @cp.size
        end

        it "length" do
          @a.should_receive(:length)
          @cp.length
        end

        it "empty?" do
          @a.should_receive(:empty?)
          @cp.empty?
        end

        it "any?" do
          @a.should_receive(:any?)
          @cp.any?
        end

        it "many?" do
          @a.should_receive(:many?)
          @cp.many?
        end

        it "include?" do
          @a.should_receive(:include?)
          @cp.include?(double)
        end

        it "reload (and return self)" do
          @a.should_receive(:reload)
          @a.should_receive(:load_target).twice.and_return([])
          @cp.reload.should == @cp
        end
      end


      it "should define == to load the target and then compare" do
        @a.should_receive(:load_target)
        @cp == [double, double, double]
      end

      it "should define to_ary to load the target and then duplicate it" do
        @a.should_receive(:load_target).and_return([double, double, double])
        @cp.to_ary
      end

      it "should define to_a as an alias for to_ary" do
        @a.should_receive(:load_target).and_return([double, double, double])
        @cp.to_a
      end

      it "should define << to concat records and return self" do
        @a.should_receive(:load_target).twice.and_return([])
        @a.should_receive(:concat).with([[1, 2, 3]]).and_return([1, 2, 3])
        (@cp << [1, 2, 3]).should == @cp
      end

      it "should define push (as an alias for <<) to concat records and return self" do
        @a.should_receive(:load_target).twice.and_return([])
        @a.should_receive(:concat).with([[1, 2, 3]]).and_return([1, 2, 3])
        @cp.push([1, 2, 3]).should == @cp
      end

      it "should define append (as an alias for <<) to concat records and return self" do
        @a.should_receive(:load_target).twice.and_return([])
        @a.should_receive(:concat).with([[1, 2, 3]]).and_return([1, 2, 3])
        @cp.append([1, 2, 3]).should == @cp
      end

      it "should raise an error for prepend" do
        expect { @cp.prepend }.
          to raise_error(NoMethodError, "prepend on association is not defined. Please use << or append")
      end

    end
  end
end
