require 'spec_helper'

    #  Association
    #    CollectionAssociation:
    #      HasAndBelongsToManyAssociation => has_and_belongs_to_many
    #      HasManyAssociation => has_many
    #        HasManyThroughAssociation + ThroughAssociation => has_many :through


class Owner < OceanDynamo::Table
  dynamo_schema(create: true) do
    attribute :thing
  end
end

class Target < OceanDynamo::Table
  dynamo_schema(create: true) do
    attribute :name
  end
end


module OceanDynamo
  module Associations

    describe CollectionAssociation do

      before :each do
        @o = Owner.create!
        @r = double(klass: Target)
        @ca = CollectionAssociation.new(@o, @r)
      end


      it "should inherit from Association" do
        @ca.should be_an Association
      end


      it "should have a reset method which sets @target to []" do
        @ca.reset
        @ca.target.should == []
        @ca.loaded?.should == false
      end



    end
  end
end
