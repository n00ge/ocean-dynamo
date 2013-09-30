require 'spec_helper'

# This is temporary
class Parent < OceanDynamo::Table; end
class Child < OceanDynamo::Table; end
class Pet < OceanDynamo::Table; end


# The parent class
class Parent < OceanDynamo::Table
  dynamo_schema(create: true) do
  end
  has_many :children
  has_many :pets
end


# The Child class
class Child < OceanDynamo::Table
  dynamo_schema(:uuid, create: true) do
  end
  belongs_to :parent
end


# Another child class, Pet
class Pet < OceanDynamo::Table
  dynamo_schema(:uuid, create: true) do
  end
  belongs_to :parent
end


class SpaceCadet < OceanDynamo::Table; end;



describe Parent do

  before :all do
    Parent.establish_db_connection
    Child.establish_db_connection
    Pet.establish_db_connection
  end


  it "should not require the child class to be already defined"


  it "should be saveable" do
    Parent.create!
  end

  it "should have a has_many class macro" do
    Parent.should respond_to :has_many
  end

  it "should require an argument to has_many" do
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


  it "should be reachable from all its children" do
    p = Parent.create!
    c1 = Child.create! parent: p
    c2 = Child.create! parent: p
    c3 = Child.create! parent: p
    c1.reload
    c1.parent.should == p
    c2.reload
    c2.parent.should == p
    c3.reload
    c3.parent.should == p
  end


  describe "#children?" do

    it "should return false for an unpersisted parent" do
      p = Parent.new
      p.children?.should == false
    end

    it "should return false for a persisted parent without children" do
      p = Parent.create!
      p.children?.should == false
    end

    it "should return true for a persisted parent with children" do
      p = Parent.create!
      Child.create! parent: p
      p.children?.should == true
    end
  end


  describe "#children" do

    it "should return nil for an unpersisted Parent" do
      p = Parent.new
      p.children.should == nil
    end

    it "should return an array for a persisted Parent" do
      p = Parent.create!
      children = p.children
      children.should be_an Array
    end

    it "should be instantiatable as instances" do
      Child.create!(parent: Parent.create!)
    end

    it "should store and return an array for a persisted Parent" do
      p = Parent.create!
      c1 = Child.create! parent: p
      c2 = Child.create! parent: p
      c3 = Child.create! parent: p
      children = p.children
      children.should include c1
      children.should include c2
      children.should include c3
    end

    it "should take an optional boolean which if true should reload the relation" do
      p = Parent.create!
      p.children.should == []
      c = Child.create! parent: p
      p.children.should == []
      p.children(true).should == [c]
    end
  end


  describe "#pets" do

    it "should return nil for an unpersisted Parent" do
      p = Parent.new
      p.pets.should == nil
    end

    it "should return an array of Pets for a persisted Parent" do
      p = Parent.create!
      Pet.create! parent: p
      pets = p.pets
      pets.should be_an Array
      pets.should_not == []
      pets.first.should be_a Pet
    end

    it "should be instantiatable as instances" do
      Pet.create!(parent: Parent.create!)
    end

    it "should return an array for a persisted Parent" do
      p = Parent.create!
      c1 = Pet.create! parent: p  # We build these by hand until
      c2 = Pet.create! parent: p  # the association proxies are
      c3 = Pet.create! parent: p  # in place
      pets = p.pets               # Cache them locally for faster tests
      pets.should include c1
      pets.should include c2
      pets.should include c3
    end
  end


  describe "associations:" do

    before :each do
      Parent.delete_all
      Child.delete_all
      Pet.delete_all
      @homer = Parent.create!
        @bart = Child.create parent: @homer
        @lisa = Child.create parent: @homer
        @maggie = Child.create parent: @homer

      @marge = Parent.create!

      @peter = Parent.create!
        @meg = Child.create! parent: @peter
        @chris = Child.create! parent: @peter
        @stewie = Child.create parent: @peter

      @lois = Parent.create!
        @brian = Pet.create! parent: @lois
    end


    it "should have findable children" do
      @lisa.parent.should == @homer
      Child.find(@homer.id, @lisa.uuid).should == @lisa
    end


    describe "reading:" do

      it "Homer should have three children" do
        @homer.children.length.should == 3
      end

      it "Homer should have no pets" do
        @homer.pets.length.should == 0
      end


      it "Marge should have no children" do
        @marge.children.length.should == 0
      end

      it "Marge should have no pets" do
        @marge.pets.length.should == 0
      end


      it "Peter should have three children" do
        @peter.children.length.should == 3
      end

      it "Peter should have no pets" do
        @peter.pets.length.should == 0
      end


      it "Lois should have no children" do
        @lois.children.length.should == 0
      end

      it "Lois should have one pet" do
        @lois.pets.length.should == 1
      end
    end


    describe "writing:" do

      it "should not store arrays containing objects of incompatible type" do
        expect { @homer.pets = [@maggie]; @homer.save! }.
          to raise_error(OceanDynamo::AssociationTypeMismatch, "an array element is not a Pet")
      end

      it "should not store non-arrays" do
        expect { @homer.pets = @maggie; @homer.save! }.
          to raise_error(OceanDynamo::AssociationTypeMismatch, "not an array or nil")
        expect { @homer.pets = "lalala"; @homer.save! }.
          to raise_error(OceanDynamo::AssociationTypeMismatch, "not an array or nil")
      end

      it "should store nil" do
        expect { @homer.pets = nil }.not_to raise_error
        expect { @homer.pets = false }.not_to raise_error
        expect { @homer.pets = "" }.not_to raise_error
        expect { @homer.pets = " " }.not_to raise_error
      end

      it "should destroy all children not in the new set" do
        @peter.children = [@chris]
        @peter.save!
        @peter.reload
        @peter.children.length.should == 1
        Child.find_by_key(@peter.id, @meg.uuid).should == nil
        Child.find_by_key(@peter.id, @chris.uuid).should == @chris
        Child.find_by_key(@peter.id, @stewie.uuid).should == nil
      end
    end


    describe "destroying:" do

        it "should behave like dependent: destroy" do
          Child.count.should == 6
          @homer.destroy
          expect { @homer.reload(consistent: true) }.to raise_error(OceanDynamo::RecordNotFound)
          expect { @bart.reload(consistent: true) }.to raise_error(OceanDynamo::RecordNotFound)
          expect { @lisa.reload(consistent: true) }.to raise_error(OceanDynamo::RecordNotFound)
          expect { @maggie.reload(consistent: true) }.to raise_error(OceanDynamo::RecordNotFound)
          Child.count.should == 3
          @peter.destroy
          expect { @peter.reload(consistent: true) }.to raise_error(OceanDynamo::RecordNotFound)
          expect { @meg.reload(consistent: true) }.to raise_error(OceanDynamo::RecordNotFound)
          expect { @chris.reload(consistent: true) }.to raise_error(OceanDynamo::RecordNotFound)
          expect { @stewie.reload(consistent: true) }.to raise_error(OceanDynamo::RecordNotFound)
          Child.count.should == 0
        end
    end
  end

  # it "should implement #children <<"
  # it "should implement #children_singular_ids"
  # it "should implement #children_singular_ids="

  # it "should implement #children.delete"
  # it "should implement #children.destroy"
  # it "should implement #children.clear"
  # it "should implement #children.empty?"
  # it "should implement #children.size"
  # it "should implement #children.find"
  # it "should implement #children.where"
  # it "should implement #children.exists?"
  # it "should implement #children.build"
  # it "should implement #children.create"
end


