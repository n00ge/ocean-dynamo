require 'spec_helper'

class Badabing < OceanDynamo::Table
  dynamo_schema(:uuid, :digitus, create:true) do
    attribute :digitus, :integer
  end
end


describe Badabing do

  before :each do
    Badabing.delete_all
  end

  it "should set the keys correctly" do
    Badabing.table_hash_key.should == :uuid
    Badabing.table_range_key.should == :digitus
    Badabing.fields.should include :digitus
  end

  it "should be instantiatiable" do
    v = Badabing.new
  end

  it "should be invalid if the range key is absent" do
    v = Badabing.new()
    v.valid?.should == false
    v.errors.messages.should == {digitus: ["can't be blank"]}
  end

  it "should be persistable when both args are specified" do
    v = Badabing.create! uuid: "foo", digitus: 10000
    v.should be_a Badabing
    v.uuid.should == "foo"
    v.digitus.should == 10000
  end

  it "should assign a UUID to the hash key when unspecified" do
    v = Badabing.create! digitus: 555
    v.uuid.should be_a String
    v.uuid.should_not == ""
  end

  it "should not persist if the range key is empty or unspecified" do
    expect { Badabing.create! uuid: "foo", digitus: nil }.to raise_error(OceanDynamo::RecordInvalid)
    expect { Badabing.create! uuid: "foo", digitus: false }.to raise_error(OceanDynamo::RecordInvalid)
    expect { Badabing.create! uuid: "foo", digitus: "" }.to raise_error(OceanDynamo::RecordInvalid)
    expect { Badabing.create! uuid: "foo", digitus: "  " }.to raise_error(OceanDynamo::RecordInvalid)
  end

  it "instances should be findable" do
    orig = Badabing.create! digitus: 100000
    found = Badabing.find(orig.uuid, 100000, consistent: true)
    found.should == orig
  end

  it "instances should be reloadable" do
    i = Badabing.create! uuid: "quux", digitus: 98765
    i.reload
  end

end
