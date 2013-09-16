require 'spec_helper'

# This is temporary
class Parent < OceanDynamo::Base; end
class Child < OceanDynamo::Base; end
class Pet < OceanDynamo::Base; end


# The parent class
class Parent < OceanDynamo::Base
  dynamo_schema(create: true) do
  end
  has_many :children
  has_many :pets
end


# The Child class
class Child < OceanDynamo::Base
  dynamo_schema(:uuid, create: true) do
  end
  belongs_to :parent
end


# Another child class, Pet
class Pet < OceanDynamo::Base
  dynamo_schema(:uuid, create: true) do
  end
  belongs_to :parent
end


class SpaceCadet < OceanDynamo::Base; end;



describe Parent do

  it "should be saveable" do
    Parent.create!
  end

  it "should have a .has_many method" do
    Parent.should respond_to :has_many
  end

  it "should require an argument" do
    expect { Parent.has_many() }.to raise_error(ArgumentError)
  end

  it "should know it has a :has_many relation to the Child class" do
    Parent.relates_to(Child).should == :has_many
  end

  it "should know it has a :has_many relation to the Kid class" do
    Parent.relates_to(Pet).should == :has_many
  end

  it "should know it has no relation to the SpaceCadet class" do
    Parent.relates_to(SpaceCadet).should == nil
  end

  it "should have no extra attributes" do
    Parent.new.attributes.should == { 
      "id"=>"", 
      "created_at"=>nil, "updated_at"=>nil, "lock_version"=>0
    }
  end

  it "child class Child should have one extra attribute" do
    Child.new.attributes.should == {
      "uuid"=>"", "parent_id"=>nil,
      "created_at"=>nil, "updated_at"=>nil, "lock_version"=>0 
    }
  end

  it "should implement #children" do
    p = Parent.new
    p.should respond_to :children
  end


  describe "#children" do

    it "should return nil for an unpersisted Parent" do
      p = Parent.new
      p.children.should == nil
    end

    it "should return an array for a persisted Parent" do
      p = Parent.create!
      p.children.should == []
    end

  end

end


