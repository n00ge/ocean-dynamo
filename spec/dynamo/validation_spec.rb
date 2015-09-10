require 'spec_helper'

class Bang < OceanDynamo::Table

  dynamo_schema(:uuid, create: true, table_name_suffix: Api.basename_suffix) do
    attribute :v,    :float,  default: 1.0
    attribute :must, :string, default: "mandatory"
    attribute :soso, :string, default: "updated"
    attribute :hate, :string, default: "exceptional"
  end

  validates :must, presence: true
  validates :soso, presence: { on: :update }
  validates :hate, presence: { strict: true }

end




describe Bang do

  before :each do
    @i = Bang.new
  end


  it "should be persistable" do
    @i.save!
  end

  it "should require must" do
    @i.must = nil
    expect(@i.save).to eq false
    expect(@i.errors[:must]).to eq ["can't be blank"]
  end

  it "should not require soso at create, but at update" do
    expect(@i.save).to eq true
    @i.soso = nil
    expect(@i.save).to eq false
    expect(@i.errors[:soso]).to eq ["can't be blank"]
  end

  it "should raise an exception if hate is nil" do
    @i.hate = false
    expect { @i.save }.to raise_error ActiveModel::StrictValidationFailed
  end


  it "valid? should take new_record? into account" do
    expect(@i.valid?).to eq true
    @i.save!
    @i.soso = false
    expect(@i.valid?).to eq false
  end





end

