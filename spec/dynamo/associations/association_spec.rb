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
        expect(@a.owner).to eq @o
        expect(@a.reflection).to eq @r
        expect { @a.owner = :nono }.to raise_error NoMethodError
        expect { @a.reflection = :never }.to raise_error NoMethodError
      end

      it "should have a target and a reader" do
        expect(@a.target).to eq nil
      end

      it "should have a #loaded? flag method which initially should be false" do
        expect(@a.loaded?).to eq false
      end

      it "should have a #loaded! method which sets #loaded flag to true" do
        @a.loaded!
        expect(@a.loaded?).to eq true
      end

      it "should have a reset method which resets the target and the loaded flag" do
        @a.loaded!
        expect(@a.loaded?).to eq true
        @a.reset
        expect(@a.loaded?).to eq false
      end

      it "should have a target writer which also should set the loaded flag" do
        expect(@a.target).to eq nil
        expect(@a.loaded?).to eq false
        @a.target = []
        expect(@a.target).to eq []
        expect(@a.loaded?).to eq true
      end

      it "should have a #stale_target? method" do
        expect(@a.stale_target?).to eq false
      end

      it "should let #stale_target? return true if the target is loaded and @stale_state differs from stale_state" do
        @a.loaded!
        expect(@a.stale_target?).to eq false
        @a.instance_variable_set(:@stale_state, :foo)
        expect(@a.stale_target?).to eq true
        @a.reset
        expect(@a.stale_target?).to eq false
      end

      it "should have a klass method which defers to the reflection klass" do
        expect(@a.klass).to eq @a.reflection.klass
      end


      describe "load_target" do 

        it "should exist" do
          expect(@a).to respond_to :load_target
        end

        it "should call find_target, which subclasses should implement" do
          expect(@a).to receive(:find_target).once.and_return([])
          @a.load_target
        end

        it "should cache the loaded target and return it" do
          expect(@a).to receive(:find_target).once.and_return([])
          expect(@a.load_target).to eq []
          expect(@a.load_target).to eq []
          expect(@a.load_target).to eq []
        end
      end


      it "should have a #reload method which resets and loads the target" do
        expect(@a).to receive(:find_target).once.and_return([])
        expect(@a.reload).to eq @a
        expect(@a.loaded?).to eq true
      end

    end
  end
end
