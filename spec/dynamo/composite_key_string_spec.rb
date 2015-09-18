require 'spec_helper'

class VaVaVoom < OceanDynamo::Table
  dynamo_schema(:hash, :range, create: true, table_name_suffix: Api.basename_suffix) do
    attribute :contents
  end
end


describe VaVaVoom do
  
  before :each do
    VaVaVoom.delete_all
  end

  it "should set the keys correctly" do
    expect(VaVaVoom.table_hash_key).to eq :hash
    expect(VaVaVoom.table_range_key).to eq :range
    expect(VaVaVoom.fields).to include :range
  end

  it "should be instantiatiable" do
    v = VaVaVoom.new
  end

  it "should be invalid if the range key is absent" do
    v = VaVaVoom.new()
    expect(v.valid?).to eq false
    expect(v.errors.messages).to eq({range: ["can't be blank"]})
  end

  it "should be persistable when both args are specified" do
    v = VaVaVoom.create! hash: "foo", range: "bar"
    expect(v).to be_a VaVaVoom
    expect(v.hash).to eq "foo"
    expect(v.range).to eq "bar"
  end

  it "should assign a UUID to the hash key when unspecified" do
    v = VaVaVoom.create! range: "bar"
    expect(v.hash).to be_a String
    expect(v.hash).not_to eq ""
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
    expect(found).to eq orig
  end

  it "instances should be reloadable" do
    i = VaVaVoom.create! hash: "quux", range: "zuul"
    i.reload
  end

end
