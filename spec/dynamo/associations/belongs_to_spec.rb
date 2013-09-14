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
  belongs_to :master    # AFTER the schema definition! Enforce?
end


describe Master do
  it "Master should be saveable" do
    Master.create!
  end

  it "Master should not have a slave_id field" do
    Master.fields.should_not include :slave_id
  end

  it "Master should not have a slave field" do
    Master.fields.should_not include :slave
  end
end


describe Slave do

  it "should have a :master_id attribute" do
    Slave.fields.should include :master_id
  end

  it "should have a :master attribute" do
    Slave.fields.should include :master
  end

  it "should have a :master_id attribute with target_class: Master" do
    Slave.fields[:master_id][:target_class].should == Master
    Slave.fields[:master_id].should == {"type"=>:reference, "default"=>nil, "target_class"=>Master}
  end

  it "should have a :master attribute with target_class: Master" do
    Slave.fields[:master][:target_class].should == Master
    Slave.fields[:master].should == {"type"=>:reference, "default"=>nil, "target_class"=>Master, "no_save"=>true}
  end

  it "should not have the target_class setting on any other attributes" do
    Slave.fields[:name][:target_class].should == nil
    Slave.fields[:name].should == {"type"=>:string, "default"=>nil}
  end

  it "should assign an instance both attributes" do
    i = Slave.new
    i.attributes.should == {
      "id"=>"", 
      "created_at"=>nil, 
      "updated_at"=>nil, 
      "lock_version"=>0, 
      "name"=>"", 
      "master_id"=>nil, 
      "master"=>nil
    }
  end


  it "instances should be instantiatable" do
    Slave.create!
  end

  it "instances should be reloadable" do
    s = Slave.create!
    s.reload
  end

  it "instances should be touchable" do
    s = Slave.create!
    s.touch
  end


  it "a new instance should have nil in the rel attr" do
    Slave.new.master.should == nil
  end

  it "a new instance should have nil in the rel attr_id" do
    Slave.new.master_id.should == nil
  end


  it "a saved instance should have nil in the rel attr" do
    Slave.create!.master.should == nil
  end

  it "a saved instance should have nil in the rel attr_id" do
    Slave.create!.master_id.should == nil
  end


  it "a reloaded instance should have nil in the rel attr" do
    Slave.create!.reload.master.should == nil
  end

  it "a reloaded instance should have nil in the rel attr_id" do
    Slave.create!.reload.master_id.should == nil
  end


  it "attr_id should be directly assignable" do
    s = Slave.new
    s.master_id = "some-uurl"
    s.master_id.should == "some-uurl"
  end

  it "attr_id should be mass-assignable" do
    s = Slave.new master_id: "an-uuid"
    s.master_id.should == "an-uuid"
  end

  it "attr should be directly assignable" do
    s = Slave.new
    s.master = "some-uurl"
    s.master.should == "some-uurl"
  end

  it "attr should be mass-assignable" do
    s = Slave.new master: "any-uuid"
    s.master.should == "any-uuid"
  end


  it "attr should be able to be mass-assigned an instance of the associated type" do
    m = Master.create!
    s = Slave.new master: m
    s.master.should == m
  end

  it "attr should be able to be directly assigned an instance of the associated type" do
    m = Master.create!
    s = Slave.new
    s.master = m
    s.master.should == m
  end

  it "an instance in attr should be saved as its UUID" do
    m = Master.create!
    s = Slave.create master: m
    s.master.should == m
    s.reload
    s.attributes['master'].should be_a String
    s.attributes['master'].should_not == ""
  end

  it "an instance in attr_id should be saved as its UUID" do
    m = Master.create!
    s = Slave.create master: m
    s.master_id.should == m.id
    s.reload
    s.attributes['master_id'].should be_a String
    s.attributes['master_id'].should_not == ""
    s.master_id.should == m.id
  end

  it "an instance in attr must be of the correct target class" do
    wrong = Slave.create!
    expect { Slave.create master: wrong }.
      to raise_error(OceanDynamo::AssociationTypeMismatch, "can't save a Slave in a Master :reference")
  end

  it "an instance in attr_id must be of the correct target class" do
    wrong = Slave.create!
    expect { Slave.create master_id: wrong }.
      to raise_error(OceanDynamo::AssociationTypeMismatch, "can't save a Slave in a Master :reference")
  end

  it "the attr_id, if it contains an instance, should return the id of that instance" do
    m = Master.create!
    s = Slave.new master_id: m
    s.master_id.should == m.id
  end

  it "the attr, if it contains an instance, should load and return that instance when accessed after a save" do
    m = Master.create!
    s = Slave.create! master: m
    s.master.should == m
    s.master = nil
    s.reload
    Master.should_receive(:find).with(s.master_id).and_return m
    s.master.should == m
  end

  it "attr load should barf on an unknown key" do
    s = Slave.create! master: "whatevah"
    expect { s.master }.to raise_error(OceanDynamo::RecordNotFound, 
                                       "can't find a Master with primary key ['whatevah', nil]")
  end

  it "the attr shouldn't be persisted, only the attr_id" do
    m = Master.create!
    s = Slave.create! master: m
    s.serialized_attributes['master_id'].should be_a String
    s.serialized_attributes['master'].should == nil
  end

  it "the attr, when loaded, should replace the string key with the instance" do
    m = Master.create!
    s = Slave.create! master: m
    s.reload
    Master.should_receive(:find).with(s.master_id).and_return m
    s.master.should == m
    s.master.should == m
    s.master.should == m
  end


end
