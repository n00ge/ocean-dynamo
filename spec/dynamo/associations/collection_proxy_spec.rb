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
        expect(@cp).to be_a Relation
      end

      it "should set @association to the second argument" do
        expect(@cp.instance_variable_get(:@association)).to eq @a
      end

      it "should define proxy_association to retrieve @association" do
        expect(@cp.proxy_association).to eq @a
      end


      describe "should let @association handle" do

        it "target" do
          expect(@a).to receive(:target)
          @cp.target
        end

        it "load_target" do
          expect(@a).to receive(:load_target)
          @cp.load_target
        end

        it "loaded?" do
          expect(@a).to receive(:loaded?)
          @cp.loaded?
        end

        it "select" do
          expect(@a).to receive(:select)
          @cp.select
        end

        it "find" do
          expect(@a).to receive(:find)
          @cp.find
        end

        it "first" do
          expect(@a).to receive(:first)
          @cp.first
        end

        it "last" do
          expect(@a).to receive(:last)
          @cp.last
        end

        it "build" do
          expect(@a).to receive(:build)
          @cp.build
        end

        it "new (as an alias for build)" do
          expect(@a).to receive(:build)
          @cp.new
        end

        it "create" do
          expect(@a).to receive(:create)
          @cp.create
        end

        it "create!" do
          expect(@a).to receive(:create!)
          @cp.create!
        end

        it "concat" do
          expect(@a).to receive(:concat)
          @cp.concat
        end

        it "replace" do
          expect(@a).to receive(:replace)
          @cp.replace([double, double, double])
        end

        it "delete_all" do
          expect(@a).to receive(:delete_all)
          @cp.delete_all
        end

        it "should define clear as delete_all returning self" do
          expect(@a).to receive(:load_target).twice.and_return([double])
          expect(@a).to receive(:delete_all)
          expect(@cp.clear).to eq @cp
        end

        it "destroy_all" do
          expect(@a).to receive(:destroy_all)
          @cp.destroy_all
        end

        it "delete" do
          expect(@a).to receive(:delete)
          @cp.delete
        end

        it "destroy" do
          expect(@a).to receive(:destroy)
          @cp.destroy
        end

        it "distinct" do
          expect(@a).to receive(:distinct)
          @cp.distinct
        end

        it "uniq (as an alias for distinct)" do
          expect(@a).to receive(:distinct)
          @cp.uniq
        end

        it "count" do
          expect(@a).to receive(:count)
          @cp.count
        end

        it "size" do
          expect(@a).to receive(:size)
          @cp.size
        end

        it "length" do
          expect(@a).to receive(:length)
          @cp.length
        end

        it "empty?" do
          expect(@a).to receive(:empty?)
          @cp.empty?
        end

        it "any?" do
          expect(@a).to receive(:any?)
          @cp.any?
        end

        it "many?" do
          expect(@a).to receive(:many?)
          @cp.many?
        end

        it "include?" do
          expect(@a).to receive(:include?)
          @cp.include?(double)
        end

        it "reload (and return self)" do
          expect(@a).to receive(:reload)
          expect(@a).to receive(:load_target).twice.and_return([])
          expect(@cp.reload).to eq @cp
        end
      end


      it "should define == to load the target and then compare" do
        expect(@a).to receive(:load_target)
        @cp == [double, double, double]
      end

      it "should define to_ary to load the target and then duplicate it" do
        expect(@a).to receive(:load_target).and_return([double, double, double])
        @cp.to_ary
      end

      it "should define to_a as an alias for to_ary" do
        expect(@a).to receive(:load_target).and_return([double, double, double])
        @cp.to_a
      end

      it "should define << to concat records and return self" do
        expect(@a).to receive(:load_target).twice.and_return([])
        expect(@a).to receive(:concat).with([[1, 2, 3]]).and_return([1, 2, 3])
        expect(@cp << [1, 2, 3]).to eq @cp
      end

      it "should define push (as an alias for <<) to concat records and return self" do
        expect(@a).to receive(:load_target).twice.and_return([])
        expect(@a).to receive(:concat).with([[1, 2, 3]]).and_return([1, 2, 3])
        expect(@cp.push([1, 2, 3])).to eq @cp
      end

      it "should define append (as an alias for <<) to concat records and return self" do
        expect(@a).to receive(:load_target).twice.and_return([])
        expect(@a).to receive(:concat).with([[1, 2, 3]]).and_return([1, 2, 3])
        expect(@cp.append([1, 2, 3])).to eq @cp
      end

      it "should raise an error for prepend" do
        expect { @cp.prepend }.
          to raise_error(NoMethodError, "prepend on association is not defined. Please use << or append")
      end

    end
  end
end
