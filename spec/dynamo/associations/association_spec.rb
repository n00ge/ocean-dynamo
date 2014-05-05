require 'spec_helper'

class Owner < OceanDynamo::Table
  dynamo_schema(create: true, table_name_suffix: Api.basename_suffix) do
    attribute :thing
  end
end

class Target < OceanDynamo::Table
  dynamo_schema(create: true, table_name_suffix: Api.basename_suffix) do
    attribute :name
  end
end

module OceanDynamo
  module Associations

    describe Association do

      before :each do
        @o = Owner.create!
        @r = double(klass: Target)
        @a = Association.new(@o, @r)
      end


      it "should take two parameters, owner and reflection, and define readers for them" do
        @a.owner.should == @o
        @a.reflection.should == @r
        expect { @a.owner = :nono }.to raise_error
        expect { @a.reflection = :never }.to raise_error
      end

      it "should have a target and a reader" do
        @a.target.should == nil
      end

      it "should have a #loaded? flag method which initially should be false" do
        @a.loaded?.should == false
      end

      it "should have a #loaded! method which sets #loaded flag to true" do
        @a.loaded!
        @a.loaded?.should == true
      end

      it "should have a reset method which resets the target and the loaded flag" do
        @a.loaded!
        @a.loaded?.should == true
        @a.reset
        @a.loaded?.should == false
      end

      it "should have a target writer which also should set the loaded flag" do
        @a.target.should == nil
        @a.loaded?.should == false
        @a.target = []
        @a.target.should == []
        @a.loaded?.should == true
      end

      it "should have a #stale_target? method" do
        @a.stale_target?.should == false
      end

      it "should let #stale_target? return true if the target is loaded and @stale_state differs from stale_state" do
        @a.loaded!
        @a.stale_target?.should == false
        @a.instance_variable_set(:@stale_state, :foo)
        @a.stale_target?.should == true
        @a.reset
        @a.stale_target?.should == false
      end

      it "should have a klass method which defers to the reflection klass" do
        @a.klass.should == @a.reflection.klass
      end


      describe "load_target" do 

        it "should exist" do
          @a.should respond_to :load_target
        end

        it "should call find_target, which subclasses should implement" do
          @a.should_receive(:find_target).once.and_return([])
          @a.load_target
        end

        it "should cache the loaded target and return it" do
          @a.should_receive(:find_target).once.and_return([])
          @a.load_target.should == []
          @a.load_target.should == []
          @a.load_target.should == []
        end
      end


      it "should have a #reload method which resets and loads the target" do
        @a.should_receive(:find_target).once.and_return([])
        @a.reload.should == @a
        @a.loaded?.should == true
      end

    end
  end
end
