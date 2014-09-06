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
      expect(found).to be_a CloudModel
      expect(found.dynamo_item).to be_an AWS::DynamoDB::Item
      expect(found.new_record?).to eq false
    end

    it "find should return a CloudModel with initalised attributes" do
      t = Time.now
      @i.started_at = t
      @i.save!
      @i.started_at = nil
      found = CloudModel.find(@i.uuid, consistent: true)
      expect(found.started_at).not_to eq nil
    end

    it "find should be able to take an array arg" do
      foo = CloudModel.create uuid: "foo"
      bar = CloudModel.create uuid: "bar"
      baz = CloudModel.create uuid: "baz"
      expect(CloudModel.find(["foo", "bar"], consistent: true)).to eq [foo, bar]
    end
  end


  describe "find_by_key" do

    it "should not barf on nonexistent keys" do
      expect { CloudModel.find_by_key('some-nonexistent-key') }.not_to raise_error
    end 

    it "find should return an existing CloudModel with a dynamo_item when successful" do
      @i.save!
      found = CloudModel.find_by_key(@i.uuid, consistent: true)
      expect(found).to be_a CloudModel
      expect(found.dynamo_item).to be_an AWS::DynamoDB::Item
      expect(found.new_record?).to eq false
    end

    it "find should return a CloudModel with initalised attributes" do
      t = Time.now
      @i.started_at = t
      @i.save!
      @i.started_at = nil
      found = CloudModel.find_by_key(@i.uuid, consistent: true)
      expect(found.started_at).not_to eq nil
    end
  end 


  it "should have a class method count" do
    expect(CloudModel.count).to be_an Integer
  end


  describe "all" do

    it "should return an array" do
      expect(CloudModel.all).to be_an Array
    end

    it "should return an array of model instances" do
      expect(CloudModel.all.first).to be_a CloudModel
    end

    it "should return as many instances as there are records in the table" do
      expect(CloudModel.all.length).to eq CloudModel.count
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
      expect(i).to eq c
    end

    it "should take the :limit keyword" do
      c = CloudModel.count
      i = 0
      CloudModel.find_each(limit: 5) { |item| i += 1 }
      expect(i).to eq 5
    end

    it "should take the :batch_size keyword and still process all items" do
      c = CloudModel.count
      i = 0
      CloudModel.find_each(batch_size: 5) { |item| i += 1 }
      expect(i).to eq c
    end
  end

end
