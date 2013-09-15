require 'spec_helper'


describe CloudModel do

  before :all do
    CloudModel.establish_db_connection
    CloudModel.delete_all
    3.times { CloudModel.create! }
  end

  before :each do
    @i = CloudModel.new
  end


  describe "find" do
  
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

    it "find should be able to take an array arg" do
      foo = CloudModel.create uuid: "foo"
      bar = CloudModel.create uuid: "bar"
      baz = CloudModel.create uuid: "baz"
      CloudModel.find(["foo", "bar"], consistent: true).should == [foo, bar]
    end
  end


  describe "find_by_key" do

    it "should not barf on nonexistent keys" do
      expect { CloudModel.find_by_key('some-nonexistent-key') }.not_to raise_error
    end 

    it "find should return an existing CloudModel with a dynamo_item when successful" do
      @i.save!
      found = CloudModel.find_by_key(@i.uuid, consistent: true)
      found.should be_a CloudModel
      found.dynamo_item.should be_an AWS::DynamoDB::Item
      found.new_record?.should == false
    end

    it "find should return a CloudModel with initalised attributes" do
      t = Time.now
      @i.started_at = t
      @i.save!
      @i.started_at = nil
      found = CloudModel.find_by_key(@i.uuid, consistent: true)
      found.started_at.should_not == nil
    end
  end 


  it "should have a class method count" do
    CloudModel.count.should be_an Integer
  end


  describe "all" do

    it "should return an array" do
      CloudModel.all.should be_an Array
    end

    it "should return an array of model instances" do
      CloudModel.all.first.should be_a CloudModel
    end

    it "should return as many instances as there are records in the table" do
      CloudModel.all.length.should == CloudModel.count
    end

  end


  describe "find_each" do

    before :all do
      CloudModel.delete_all
      24.times { CloudModel.create! }
    end


    it "should take a block" do
      CloudModel.find_each { |item| }
    end

    it "should yield to the block as many times as there are items in the table" do
      c = CloudModel.count
      i = 0
      CloudModel.find_each { |item| i += 1 }
      i.should == c
    end

    it "should take the :limit keyword" do
      c = CloudModel.count
      i = 0
      CloudModel.find_each(limit: 5) { |item| i += 1 }
      i.should == 5
    end

    it "should take the :batch_size keyword and still process all items" do
      c = CloudModel.count
      i = 0
      CloudModel.find_each(batch_size: 5) { |item| i += 1 }
      i.should == c
    end
  end

end
