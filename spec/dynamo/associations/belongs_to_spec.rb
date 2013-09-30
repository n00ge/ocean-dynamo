require 'spec_helper'


class Master < OceanDynamo::Table
  dynamo_schema(create: true) do
    attribute :name
  end
end


class Slave < OceanDynamo::Table
  dynamo_schema(:uuid, create: true) do
    attribute :name
  end
  belongs_to :master
end


class Other < OceanDynamo::Table
end



describe Slave do

  before :each do
    @m = Master.create!
  end


  it "should not require the parent class to be already defined"

  it "should handle a parent table with a composite key (declare using composite_key: true)"


  it "should match the DynamoDB hash_key" do
    Slave.establish_db_connection
    Slave.table_hash_key.to_s.should == Slave.dynamo_table.hash_key.name
  end

  it "should match the DynamoDB range_key" do
    Slave.establish_db_connection
    Slave.table_range_key.to_s.should == Slave.dynamo_table.range_key.name
  end


  it "should barf on an explicitly specified range key"
  it "should barf on an explicitly specified hash key of :id"


  it "should have a range key named :uuid" do
    Slave.table_range_key.should == :uuid
  end

  it "should have a hash key named :master_id" do
    Slave.table_hash_key.should == :master_id
  end


  it "should have an :uuid attribute" do
    Slave.fields.should include :uuid
    i = Slave.new
    i.uuid.should == ""            # String because it's an empty UUID
    i.uuid = "2345"
    i[:uuid].should == "2345"
  end

  it "should not have a :master attribute" do
    Slave.fields.should_not include :master
  end

  it "should have a :master_id attribute" do
    Slave.fields.should include :master_id
    i = Slave.new
    i.master_id.should == nil      # nil because it's an empty reference
    i.master_id = "the-master-id"
    i[:master_id].should == "the-master-id"
  end


  it "should have a :master_id attribute with target_class: Master" do
    Slave.fields[:master_id][:target_class].should == Master
  end

  it "should not have the target_class setting on any other attributes" do
    Slave.fields[:name][:target_class].should == nil
  end


  it "the :id reader should read the :master_id attribute" do
    i = Slave.new
    i.master_id = "hash key"
    i.attributes.should == {
      "uuid"=>"", 
      "created_at"=>nil, 
      "updated_at"=>nil, 
      "lock_version"=>0, 
      "name"=>"", 
      "master_id"=>"hash key"
    }
    i[:master_id].should == "hash key"
    i.id.should == "hash key"
    i[:id].should == "hash key"
  end

  it "the :id writer should set the :master_id attribute" do
    i = Slave.new
    i.id = "I'm the ID now"
    i.attributes.should == {
      "uuid"=>"", 
      "created_at"=>nil, 
      "updated_at"=>nil, 
      "lock_version"=>0, 
      "name"=>"", 
      "master_id"=>"I'm the ID now"
    }
  end

  it "the :master_id reader should read the :master_id attribute" do
    i = Slave.new
    i.master_id = "range key"
    i.attributes.should == {
      "uuid"=>"", 
      "created_at"=>nil, 
      "updated_at"=>nil, 
      "lock_version"=>0, 
      "name"=>"", 
      "master_id"=>"range key"
    }
    i.master_id.should == "range key"
    i[:master_id].should == "range key"
  end



  it "instances should be instantiatable" do
    Slave.create! master: @m
  end

  it "instances should be reloadable" do
    s = Slave.create! master: @m
    s.reload
  end

  it "instances should be touchable" do
    s = Slave.create! master: @m
    s.touch
  end


  it "a new instance should have nil in the assocation attr" do
    Slave.new.master.should == nil
  end

  it "a new instance should have nil in attr_id" do
    Slave.new.master_id.should == nil
  end


  it "a saved instance should not have nil in the assocation attr" do
    Slave.create!(master:@m).master.should_not == nil
  end

  it "a saved instance should not have nil in attr_id" do
    Slave.create!(master: @m).master_id.should_not == nil
  end


  it "a reloaded instance should not have nil in the assocation attr" do
    Slave.create!(master: @m).reload.master.should_not == nil
  end

  it "a reloaded instance should not have nil in attr_id" do
    Slave.create!(master: @m).reload.master_id.should_not == nil
  end


  it "attr_id should be directly assignable" do
    s = Slave.new
    s.master_id = "some-uuid"
    s.master_id.should == "some-uuid"
    s.instance_variable_get(:@master).should == nil
  end

  it "attr_id should be mass-assignable" do
    s = Slave.new master_id: "an-uuid"
    s.master_id.should == "an-uuid"
    s.instance_variable_get(:@master).should == nil
  end

  it "attr should be directly assignable" do
    s = Slave.new
    s.master = @m
    s.instance_variable_get(:@master).should == @m
    s.master.should == @m
    s.master_id.should be_a String
    s.master_id.should == @m.id
  end

  it "attr should be mass-assignable" do
    s = Slave.new master: @m
    s.instance_variable_get(:@master).should == @m
    s.master.should == @m
    s.master_id.should be_a String
    s.master_id.should == @m.id
  end


  it "attr should be able to be mass-assigned an instance of the associated type" do
    s = Slave.new master: @m
    s.master.should == @m
  end


  it "an instance in attr must be of the correct target class" do
    wrong = Slave.create!(master: @m)
    expect { Slave.create master: wrong }.
      to raise_error(OceanDynamo::AssociationTypeMismatch, "can't save a Slave in a Master foreign key")
  end

  it "should barf on an instance in attr_id" do
    wrong = Slave.create!(master_id: @m.id)
    expect { Slave.create master_id: wrong }.
      to raise_error(StandardError, "Foreign key master_id must be nil or a string")
  end

  it "the attr, if it contains an instance, should load and return that instance when accessed after a save" do
    s = Slave.create! master: @m
    s.master.should == @m
    s.reload
    s.master.should == @m
  end

  it "attr load should barf on an unknown key" do
    s = Slave.create! master_id: "whatevah"
    expect { s.master }.to raise_error(OceanDynamo::RecordNotFound, 
                                       "can't find a Master with primary key ['whatevah', nil]")
  end

  it "the attr shouldn't be persisted, only the attr_id" do
    s = Slave.create! master: @m
    s.send(:serialized_attributes)['master_id'].should be_a String
    s.send(:serialized_attributes)['master'].should == nil
  end

  it "the attr should be cached" do
    s = Slave.create! master: @m
    s.reload
    Master.should_receive(:find).and_return @m
    s.master.should == @m
    s.master.should == @m
    s.master.should == @m
  end


  it "must not allow more than one belongs_to association per model" do
    expect { Slave.belongs_to :other }.
      to raise_error(OceanDynamo::AssociationMustBeUnique, 
                     "Slave already belongs_to Master")
  end


  it "should define build_master"

  it "should define create_master"


end
