require 'spec_helper'


class Master < OceanDynamo::Base

  dynamo_schema(create: true) do
    attribute :name
  end

end


class Slave < OceanDynamo::Base

  dynamo_schema(create: true) do
    attribute :name
  end

  #belongs_to :owner

end


describe "The belongs_to relation" do

  it "Master should be saveable" do
    Master.create!
  end

  it "Slave should be saveable" do
    Slave.create!
  end




end
