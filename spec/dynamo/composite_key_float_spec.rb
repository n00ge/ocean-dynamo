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
    expect(Kaching.table_hash_key).to eq :uuid
    expect(Kaching.table_range_key).to eq :digitus
    expect(Kaching.fields).to include :digitus
  end

  it "should be instantiatiable" do
    v = Kaching.new
  end

  it "should be invalid if the range key is absent" do
    v = Kaching.new()
    expect(v.valid?).to eq false
    expect(v.errors.messages).to eq({digitus: ["can't be blank"]})
  end

  it "should be persistable when both args are specified" do
    v = Kaching.create! uuid: "foo", digitus: 3.14
    expect(v).to be_a Kaching
    expect(v.uuid).to eq "foo"
    expect(v.digitus).to eq 3.14
  end

  it "should assign a UUID to the hash key when unspecified" do
    v = Kaching.create! digitus: 23.1
    expect(v.uuid).to be_a String
    expect(v.uuid).not_to eq ""
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
    expect(found).to eq orig
  end

  it "instances should be reloadable" do
    i = Kaching.create! uuid: "quux", digitus: 12.34
    i.reload
  end

end
