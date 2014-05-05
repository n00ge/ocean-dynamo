require 'spec_helper'

class Kaching < OceanDynamo::Table
  dynamo_schema(:uuid, :digitus, create:true, table_name_suffix: Api.basename_suffix) do
    attribute :digitus, :float
  end
end


describe Kaching do

  before :each do
    Kaching.delete_all
  end

  it "should set the keys correctly" do
    Kaching.table_hash_key.should == :uuid
    Kaching.table_range_key.should == :digitus
    Kaching.fields.should include :digitus
  end

  it "should be instantiatiable" do
    v = Kaching.new
  end

  it "should be invalid if the range key is absent" do
    v = Kaching.new()
    v.valid?.should == false
    v.errors.messages.should == {digitus: ["can't be blank"]}
  end

  it "should be persistable when both args are specified" do
    v = Kaching.create! uuid: "foo", digitus: 3.14
    v.should be_a Kaching
    v.uuid.should == "foo"
    v.digitus.should == 3.14
  end

  it "should assign a UUID to the hash key when unspecified" do
    v = Kaching.create! digitus: 23.1
    v.uuid.should be_a String
    v.uuid.should_not == ""
  end

  it "should not persist if the range key is empty or unspecified" do
    expect { Kaching.create! uuid: "foo", digitus: nil }.to raise_error(OceanDynamo::RecordInvalid)
    expect { Kaching.create! uuid: "foo", digitus: false }.to raise_error(OceanDynamo::RecordInvalid)
    expect { Kaching.create! uuid: "foo", digitus: "" }.to raise_error(OceanDynamo::RecordInvalid)
    expect { Kaching.create! uuid: "foo", digitus: "  " }.to raise_error(OceanDynamo::RecordInvalid)
  end

  it "instances should be findable" do
    orig = Kaching.create! digitus: 17.0
    found = Kaching.find(orig.uuid, 17.0, consistent: true)
    found.should == orig
  end

  it "instances should be reloadable" do
    i = Kaching.create! uuid: "quux", digitus: 12.34
    i.reload
  end

end
