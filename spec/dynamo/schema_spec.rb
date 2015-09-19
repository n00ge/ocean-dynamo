require 'spec_helper'

class Quux < OceanDynamo::Table
  dynamo_schema(:index, :foo, table_name_suffix: Api.basename_suffix) do
    attribute :index,     :string,  default: "unlikely"
    attribute :foo,       :string
    attribute :bar,       :string,  default: "zuul"
    attribute :baz,       :float,   default: 3.141592
    attribute :created_by
    attribute :updated_by
  end
end


class Blahonga < OceanDynamo::Table
  dynamo_schema(:uuid, table_name: "caramba",
                       table_name_prefix: "pre_",
                       read_capacity_units: 100,
                       write_capacity_units: 50,
                       connect: false,
                       create: true, table_name_suffix: Api.basename_suffix,
                       locking: :optimism,
                       timestamps: [:made_at, :changed_at]
               ) do
    attribute :thingy
  end
end


class Zulu < OceanDynamo::Table
  dynamo_schema(locking: nil, connect: false) do
    attribute :minimal
  end
end


class Idi < OceanDynamo::Table
  dynamo_schema(create: true, table_name_suffix: Api.basename_suffix) do
    attribute :unused
  end
end


describe Zulu do
  
  it "the default key must be :id" do
    expect(Zulu.table_hash_key).to eq :id
  end
end


describe Idi do

  it "the default key must be :id" do
    expect(Idi.table_hash_key).to eq :id
  end

  it "the attributes hash should be properly initialised" do
    i = Idi.new
    expect(i.attributes).to eq({"id"=>"", "created_at"=>nil, "updated_at"=>nil, "lock_version"=>0, "unused"=>""})
    expect(i.attributes['id']).to eq ""
  end

  it "the persisted :id table_hash_key must be a UUID" do
    i = Idi.create!
    expect(i.attributes['id']).to be_a String
    expect(i.attributes['id']).not_to eq ""
    expect(i.attributes['id'].length).to eq 36
  end

  it "should correctly evaluate the id method when new" do
    i = Idi.new
    expect(i.id).not_to eq nil
    expect(i.id).to eq ""
    expect(i.id).to be_a String
  end

  it "should correctly evaluate the id method when persisted" do
    i = Idi.create!
    expect(i.id).not_to eq nil
    expect(i.id).not_to eq ""
    expect(i.id).to be_a String
  end

  it "the uuid attribute should not be available" do
    i = Idi.new
    expect { i.uuid }.to raise_error(NoMethodError)
  end

  it "should correctly read the :id attribute" do
    i = Idi.new
    expect(i.read_attribute(:id)).not_to eq nil
    expect(i.read_attribute(:id)).to eq ""
    expect(i.read_attribute(:id)).to be_a String
    i.save!
    expect(i.read_attribute(:id)).not_to eq nil
    expect(i.read_attribute(:id)).not_to eq ""
    expect(i.read_attribute(:id)).to be_a String
  end

  it "should correctly read the 'id' attribute" do
    i = Idi.new
    expect(i.read_attribute('id')).not_to eq nil
    expect(i.read_attribute('id')).to eq ""
    expect(i.read_attribute('id')).to be_a String
    i.save!
    expect(i.read_attribute('id')).not_to eq nil
    expect(i.read_attribute('id')).not_to eq ""
    expect(i.read_attribute('id')).to be_a String
  end

  it "should have a normal field list" do
    expect(Idi.fields).to eq({
      "id"=>{"type"=>:string, "default"=>""}, 
      "created_at"=>{"type"=>:datetime, "default"=>nil}, 
      "updated_at"=>{"type"=>:datetime, "default"=>nil}, 
      "lock_version"=>{"type"=>:integer, "default"=>0}, 
      "unused"=>{"type"=>:string, "default"=>nil}
    })
  end
end


describe Blahonga do

  it "should set the hash key" do
    expect(Quux.table_hash_key).to eq :index
  end

  it "should have the hash key :uuid" do
    expect(Blahonga.table_hash_key).to eq :uuid
  end

  it "should set the range key" do
    expect(Quux.table_range_key).to eq :foo
  end

  it "should default the table name like ActiveRecord" do
    expect(Quux.table_name).to eq "quuxes"
  end

  it "should allow the name to be specified" do
    expect(Blahonga.table_name).to eq "caramba"
  end

  it "should allow the name prefix to be specified" do
    expect(Blahonga.table_name_prefix).to eq "pre_"
  end

  it "should allow the name suffix to be specified" do
    expect(Blahonga.table_name_suffix).to eq Api.basename_suffix
  end

  it "should produce full table names" do
    expect(Quux.table_full_name).to eq "quuxes" + Api.basename_suffix
    expect(Blahonga.table_full_name).to eq "pre_caramba" + Api.basename_suffix
  end

  it "should default the read capacity to 10" do
    expect(Quux.table_read_capacity_units).to eq 10
  end

  it "should default the write capacity to 5" do
    expect(Quux.table_write_capacity_units).to eq 5
  end

  it "should allow the read capacity to be set" do
    expect(Blahonga.table_read_capacity_units).to eq 100
  end

  it "should allow the write capacity to be set" do
    expect(Blahonga.table_write_capacity_units).to eq 50
  end

  it "should automatically define a string attribute for the hash_key, if not given" do
    expect(Blahonga.fields['uuid']).to eq({"type" => :string, "default" => ""})
  end

  it "should respect an explicitly declared id field" do
    expect(Quux.fields['index']).to eq({"type" => :string, "default" => "unlikely"})
  end

  it "should default the table_connect_policy to :late" do
    expect(Quux.table_connect_policy).to eq :late
  end

  it "should allow the table_connect_policy to be overridden" do
    expect(Blahonga.table_connect_policy).to eq false
  end

  it "should default the table_create_policy to false" do
    expect(Quux.table_create_policy).to eq false
  end

  it "should allow the table_create_policy to be overridden" do
    expect(Blahonga.table_create_policy).to eq true
  end

  it "should default the locking attribute to :lock_version" do
    expect(Quux.lock_attribute).to eq :lock_version
  end

  it "should allow locking attribute to be overridden" do
    expect(Blahonga.lock_attribute).to eq :optimism
  end

  it "should allow locking attribute to be set to nil" do
    expect(Zulu.lock_attribute).to eq nil
  end


  it "should default the timestamps to created_at and updated_at" do
    expect(Quux.timestamp_attributes).to eq [:created_at, :updated_at]
  end

  it "should allow the timestamp attributes to be overridden" do
    expect(Blahonga.timestamp_attributes).to eq [:made_at, :changed_at]
  end

end

