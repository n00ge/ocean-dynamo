require 'spec_helper'

class Quux < OceanDynamo::Base
  dynamo_schema(:index, :foo, connect: false) do
    attribute :index,     :string,  default: "unlikely"
    attribute :foo,       :string
    attribute :bar,       :string,  default: "zuul"
    attribute :baz,       :float,   default: 3.141592
    attribute :created_by
    attribute :updated_by
  end
end


class Blahonga < OceanDynamo::Base
  dynamo_schema(table_name: "caramba",
                table_name_prefix: "pre_",
                table_name_suffix: "_post",
                read_capacity_units: 100,
                write_capacity_units: 50,
                connect: false
               ) do
    attribute :thingy
  end
end



describe Blahonga do

  it "should set the hash key" do
    Quux.table_hash_key.should == :index
  end

  it "should default the hash key to :uuid" do
    Blahonga.table_hash_key.should == :uuid
  end

  it "should set the range key" do
    Quux.table_range_key.should == :foo
  end

  it "should default the table name like ActiveRecord" do
    Quux.table_name.should == "quuxes"
  end

  it "should allow the name to be specified" do
    Blahonga.table_name.should == "caramba"
  end

  it "should allow the name prefix to be specified" do
    Blahonga.table_name_prefix.should == "pre_"
  end

  it "should allow the name suffix to be specified" do
    Blahonga.table_name_suffix.should == "_post"
  end

  it "should produce full table names" do
    Quux.table_full_name.should == "quuxes"
    Blahonga.table_full_name.should == "pre_caramba_post"
  end

  it "should default the read capacity to 10" do
    Quux.table_read_capacity_units.should == 10
  end

  it "should default the write capacity to 5" do
    Quux.table_write_capacity_units.should == 5
  end

  it "should allow the read capacity to be set" do
    Blahonga.table_read_capacity_units.should == 100
  end

  it "should allow the write capacity to be set" do
    Blahonga.table_write_capacity_units.should == 50
  end

  it "should automatically define a string attribute for the hash_key, if not given" do
    Blahonga.fields['uuid'].should == {"type" => :string, "default" => ""}
  end

  it "should respect an explicitly declared id field" do
    Quux.fields['index'].should == {"type" => :string, "default" => "unlikely"}
  end


end

