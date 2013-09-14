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
end


describe Slave do

  it "should have a :master_id attribute" do
    Slave.fields.should include :master_id
  end

  it "should have a :master attribute" do
    Slave.fields.should include :master
  end

  it "should have a :master_id attribute with a pointer: Master" do
    Slave.fields[:master_id][:pointer].should == Master
    Slave.fields[:master_id].should == {"type"=>:string, "default"=>nil, "pointer"=>Master}
  end

  it "should have a :master attribute with a pointer: Master" do
    Slave.fields[:master][:pointer].should == Master
    Slave.fields[:master].should == {"type"=>:string, "default"=>nil, "pointer"=>Master}
  end

  it "should not have the pointer setting on any other attributes" do
    Slave.fields[:name][:pointer].should == nil
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
      "master_id"=>"", 
      "master"=>""
    }
  end


  it "instances should be instantiatable" do
    Slave.create!
  end

  it "instances should be reloadable" do
    i = Slave.create!
    i.reload
  end

  it "instances should be touchable" do
    i = Slave.create!
    i.touch
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

end
