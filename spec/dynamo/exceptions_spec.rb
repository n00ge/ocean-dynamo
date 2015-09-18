require 'spec_helper'


describe CloudModel do

  before :all do
    CloudModel.establish_db_connection
  end

  it "save should not raise an exception for a valid model" do
  	i = CloudModel.new
  	expect(i.valid?).to eq true
  	expect(i.save).to eq true
  end

  it "save! should not raise an exception for a valid model" do
  	i = CloudModel.new
  	expect(i.valid?).to eq true
  	expect(i.save!).to eq true
  end


  it "save should not raise an exception for an invalid model" do
  	i = CloudModel.new
  	i.steps = nil
  	expect(i.valid?).to eq false
  	expect(i.save).to eq false
  end

  it "save! should raise an exception for a valid model" do
  	i = CloudModel.new
  	i.steps = nil
  	expect(i.valid?).to eq false
  	expect { i.save! }.to raise_error(OceanDynamo::RecordInvalid)
  end


  it "update should not raise an exception for a valid model" do
  	i = CloudModel.new
  	i.save!
  	expect(i.valid?).to eq true
  	expect(i.save).to eq true
  end

  it "update! should not raise an exception for a valid model" do
  	i = CloudModel.new
  	i.save!
  	expect(i.valid?).to eq true
  	expect(i.save!).to eq true
  end


  it "update should not raise an exception for an invalid model" do
  	i = CloudModel.new
  	i.save!
  	i.steps = nil
  	expect(i.valid?).to eq false
  	expect(i.save).to eq false
  end

  it "update! should raise an exception for a valid model" do
  	i = CloudModel.new
  	i.save!
  	i.steps = nil
  	expect(i.valid?).to eq false
  	expect { i.save! }.to raise_error(OceanDynamo::RecordInvalid)
  end


end
