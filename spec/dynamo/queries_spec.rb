require 'spec_helper'


describe CloudModel do

  before :all do
    CloudModel.establish_db_connection
  end

  before :each do
    @i = CloudModel.new
  end


  it "find should barf on nonexistent keys" do
    expect { CloudModel.find('some-nonexistent-key') }.to raise_error(OceanDynamo::RecordNotFound)
  end

  it "find should return an existing CloudModel with a dynamo_item when successful" do
    @i.save!
    found = CloudModel.find(@i.uuid, consistent: true)
    found.should be_a CloudModel
    found.dynamo_item.should be_an AWS::DynamoDB::Item
    found.new_record?.should == false
  end

  it "find should return a CloudModel with initalised attributes" do
    t = Time.now
    @i.started_at = t
    @i.save!
    @i.started_at = nil
    found = CloudModel.find(@i.uuid, consistent: true)
    found.started_at.should_not == nil
  end

  it "should have a class method count" do
    CloudModel.count.should be_an Integer
  end

end
