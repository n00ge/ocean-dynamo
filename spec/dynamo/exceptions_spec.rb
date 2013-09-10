require 'spec_helper'


describe CloudModel do

  before :all do
  	CloudModel.establish_db_connection
  end


  it "save should not raise an exception for a valid model" do
  	i = CloudModel.new
  	i.valid?.should == true
  	i.save.should == true
  end

  it "save! should not raise an exception for a valid model" do
  	i = CloudModel.new
  	i.valid?.should == true
  	i.save!.should == true
  end


  it "save should not raise an exception for an invalid model" do
  	i = CloudModel.new
  	i.steps = nil
  	i.valid?.should == false
  	i.save.should == false
  end

  it "save! should raise an exception for a valid model" do
  	i = CloudModel.new
  	i.steps = nil
  	i.valid?.should == false
  	expect { i.save! }.to raise_error(OceanDynamo::RecordInvalid)
  end


  it "update should not raise an exception for a valid model" do
  	i = CloudModel.new
  	i.save!
  	i.valid?.should == true
  	i.save.should == true
  end

  it "update! should not raise an exception for a valid model" do
  	i = CloudModel.new
  	i.save!
  	i.valid?.should == true
  	i.save!.should == true
  end


  it "update should not raise an exception for an invalid model" do
  	i = CloudModel.new
  	i.save!
  	i.steps = nil
  	i.valid?.should == false
  	i.save.should == false
  end

  it "update! should raise an exception for a valid model" do
  	i = CloudModel.new
  	i.save!
  	i.steps = nil
  	i.valid?.should == false
  	expect { i.save! }.to raise_error(OceanDynamo::RecordInvalid)
  end


end
