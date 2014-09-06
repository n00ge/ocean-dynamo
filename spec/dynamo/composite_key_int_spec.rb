require 'spec_helper'

class Badabing < OceanDynamo::Table
  dynamo_schema(:uuid, :digitus, create:true, table_name_suffix: Api.basename_suffix) do
    attribute :digitus, :integer
  end
end


describe Badabing do

  before :each do
    Badabing.delete_all
  end

  it "should set the keys correctly" do
    expect(Badabing.table_hash_key).to eq :uuid
    expect(Badabing.table_range_key).to eq :digitus
    expect(Badabing.fields).to include :digitus
  end

  it "should be instantiatiable" do
    v = Badabing.new
  end

  it "should be invalid if the range key is absent" do
    v = Badabing.new()
    expect(v.valid?).to eq false
    expect(v.errors.messages).to eq({digitus: ["can't be blank"]})
  end

  it "should be persistable when both args are specified" do
    v = Badabing.create! uuid: "foo", digitus: 10000
    expect(v).to be_a Badabing
    expect(v.uuid).to eq "foo"
    expect(v.digitus).to eq 10000
  end

  it "should assign a UUID to the hash key when unspecified" do
    v = Badabing.create! digitus: 555
    expect(v.uuid).to be_a String
    expect(v.uuid).not_to eq ""
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
    expect(found).to eq orig
  end

  it "instances should be reloadable" do
    i = Badabing.create! uuid: "quux", digitus: 98765
    i.reload
  end

end
