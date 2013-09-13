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

  belongs_to :master

end


describe Master do
  it "Master should be saveable" do
    Master.create!
  end
end


describe Slave do

  it "should be saveable" do
    Slave.create!
  end

  it "should have a :master_id attribute" do
    Slave.fields.should include :master_id
  end

  it "should implement #master" do
    s = Slave.new
    s.master.should == nil
  end

  it "should implement #master_id" do
    s = Slave.new
    s.master_id.should == nil
  end

end

