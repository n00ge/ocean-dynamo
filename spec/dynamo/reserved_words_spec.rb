require 'spec_helper'

class Dicey < OceanDynamo::Table
  dynamo_schema(:uuid, :token, create: true, table_name_suffix: Api.basename_suffix) do
    attribute :token, default: "xyzzy"
  end
end


describe Dicey do

  it "should be instantiatable" do
    Dicey.new
  end

  it "should be persistable" do
    Dicey.create!
  end

  it "should be possible to delete all instances" do
    Dicey.create!
    Dicey.create!
    Dicey.create!
    Dicey.delete_all
  end

end

