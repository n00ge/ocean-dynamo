require 'spec_helper'

class VaVaVoom < OceanDynamo::Table
  dynamo_schema(:hash, :range, create: true) do
    attribute :contents
  end
end


describe VaVaVoom do

  before :each do
    VaVaVoom.all.each { |vvv| vvv.delete }
  end

  it "should set the keys correctly" do
    VaVaVoom.table_hash_key.should == :hash
    VaVaVoom.table_range_key.should == :range
    VaVaVoom.fields.should include :range
  end

  it "should be instantiatiable" do
    v = VaVaVoom.new
  end

  it "should be invalid if the range key is absent" do
    v = VaVaVoom.new()
    v.valid?.should == false
    v.errors.messages.should == {range: ["can't be blank"]}
  end

  it "should be persistable when both args are specified" do
    v = VaVaVoom.create! hash: "foo", range: "bar"
    v.should be_a VaVaVoom
    v.hash.should == "foo"
    v.range.should == "bar"
  end

  it "should assign an UUID to the hash key when unspecified" do
    v = VaVaVoom.create! range: "bar"
    v.hash.should be_a String
    v.hash.should_not == ""
  end

  it "should not persist if the range key is empty or unspecified" do
    expect { VaVaVoom.create! hash: "foo", range: nil }.to raise_error(OceanDynamo::RecordInvalid)
    expect { VaVaVoom.create! hash: "foo", range: false }.to raise_error(OceanDynamo::RecordInvalid)
    expect { VaVaVoom.create! hash: "foo", range: "" }.to raise_error(OceanDynamo::RecordInvalid)
    expect { VaVaVoom.create! hash: "foo", range: "  " }.to raise_error(OceanDynamo::RecordInvalid)
  end

  it "instances should be findable" do
    orig = VaVaVoom.create! range: "woohoo"
    found = VaVaVoom.find(orig.hash, "woohoo", consistent: true)
    found.should == orig
  end

  it "instances should be reloadable" do
    i = VaVaVoom.create! hash: "quux", range: "zuul"
    i.reload
  end

end
