require 'spec_helper'

    #
    # CollectionAssociation is an abstract class that provides common stuff to
    # ease the implementation of association proxies that represent
    # collections. See the class hierarchy in AssociationProxy.
    #
    #  Associations
    #    Association
    #      CollectionAssociation:
    #        HasAndBelongsToManyAssociation => has_and_belongs_to_many
    #        HasManyAssociation => has_many
    #          HasManyThroughAssociation + ThroughAssociation => has_many :through
    #
    # CollectionAssociation class provides common methods to the collections
    # defined by +has_and_belongs_to_many+, +has_many+ or +has_many+ with
    # +:through association+ option.
    #


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

    describe CollectionAssociation do

      before :each do
        @o = Owner.create!
        @r = double(klass: Target)
        @ca = CollectionAssociation.new(@o, @r)
      end


      it "should inherit from Association" do
        expect(@ca).to be_an Association
      end


      it "should have a reset method which sets @target to []" do
        @ca.reset
        expect(@ca.target).to eq []
        expect(@ca.loaded?).to eq false
      end



    end
  end
end
