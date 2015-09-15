require 'spec_helper'


# The parent class
class Parent < OceanDynamo::Table
  dynamo_schema(create: true, table_name_suffix: Api.basename_suffix) do
  end
  has_many :children, dependent: :destroy
  has_many :pets,     dependent: :nullify
  has_many :cars,     dependent: :delete
end


# The Child class
class Child < OceanDynamo::Table
  dynamo_schema(:guid, create: true, table_name_suffix: Api.basename_suffix) do
  end
  belongs_to :parent
end


# Another child class, Pet
class Pet < OceanDynamo::Table
  dynamo_schema(:guid, create: true, table_name_suffix: Api.basename_suffix) do
  end
  belongs_to :parent
end


# Another child class, Car
class Car < OceanDynamo::Table
  dynamo_schema(:guid, create: true, table_name_suffix: Api.basename_suffix) do
  end
  belongs_to :parent
end


class SpaceCadet < OceanDynamo::Table; end;



describe Parent do

  before :all do
    Parent.establish_db_connection
    Child.establish_db_connection
    Pet.establish_db_connection
    Car.establish_db_connection
  end



  it "should be saveable" do
    Parent.create!
  end

  it "should have an has_many class macro" do
    expect(Parent).to respond_to :has_many
  end

  it "should require an argument to has_many" do
    expect { Parent.has_many() }.to raise_error(ArgumentError)
  end

  it "should know it has a :has_many relation to the Child class" do
    expect(Parent.relates_to(Child)).to eq :has_many
  end

  it "should know it has a :has_many relation to the Kid class" do
    expect(Parent.relates_to(Pet)).to eq :has_many
  end

  it "should know it has no relation to the SpaceCadet class" do
    expect(Parent.relates_to(SpaceCadet)).to eq nil
  end

  it "should have no extra attributes" do
    expect(Parent.new.attributes).to eq({ 
      "id"=>"", 
      "created_at"=>nil, "updated_at"=>nil, "lock_version"=>0
    })
  end

  it "child class Child should have one extra attribute" do
    expect(Child.new.attributes).to eq({
      "guid"=>"", "parent_id"=>nil,
      "created_at"=>nil, "updated_at"=>nil, "lock_version"=>0 
    })
  end


  it "should be reachable from all its children" do
    p = Parent.create!
    c1 = Child.create! parent: p
    c2 = Child.create! parent: p
    c3 = Child.create! parent: p
    c1.reload
    expect(c1.parent).to eq p
    c2.reload
    expect(c2.parent).to eq p
    c3.reload
    expect(c3.parent).to eq p
  end


  describe "#children?" do

    it "should return false for an unpersisted parent" do
      p = Parent.new
      expect(p.children?).to eq false
    end

    it "should return false for a persisted parent without children" do
      p = Parent.create!
      expect(p.children?).to eq false
    end

    it "should return true for a persisted parent with children" do
      p = Parent.create!
      Child.create! parent: p
      expect(p.children?).to eq true
    end
  end


  describe "#children" do

    it "should return nil for an unpersisted Parent" do
      p = Parent.new
      expect(p.children).to eq nil
    end

    it "should return an array for a persisted Parent" do
      p = Parent.create!
      children = p.children
      expect(children).to be_an Array
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
      expect(children).to include c1
      expect(children).to include c2
      expect(children).to include c3
    end

    it "should take an optional boolean which if true should reload the relation" do
      p = Parent.create!
      expect(p.children).to eq []
      c = Child.create! parent: p
      expect(p.children).to eq []
      expect(p.children(true)).to eq [c]
    end
  end


  describe "#pets" do

    it "should return nil for an unpersisted Parent" do
      p = Parent.new
      expect(p.pets).to eq nil
    end

    it "should return an array of Pets for a persisted Parent" do
      p = Parent.create!
      Pet.create! parent: p
      pets = p.pets
      expect(pets).to be_an Array
      expect(pets).not_to eq []
      expect(pets.first).to be_a Pet
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
      expect(pets).to include c1
      expect(pets).to include c2
      expect(pets).to include c3
    end
  end


  describe "associations:" do

    before :each do
      Parent.delete_all
      Child.delete_all
      Pet.delete_all
      Car.delete_all
      @homer = Parent.create!
        @bart = Child.create! parent: @homer
        @lisa = Child.create! parent: @homer
        @maggie = Child.create! parent: @homer

      @marge = Parent.create!
        @volvo = Car.create! parent: @marge
        @saab = Car.create! parent: @marge

      @peter = Parent.create!
        @meg = Child.create! parent: @peter
        @chris = Child.create! parent: @peter
        @stewie = Child.create parent: @peter

      @lois = Parent.create!
        @brian = Pet.create! parent: @lois
    end


    it "should have findable children" do
      expect(@lisa.parent).to eq @homer
      expect(Child.find(@homer.id, @lisa.guid)).to eq @lisa
    end


    describe "reading:" do

      it "Homer should have three children" do
        expect(@homer.children.length).to eq 3
      end

      it "Homer should have no pets" do
        expect(@homer.pets.length).to eq 0
      end


      it "Marge should have no children" do
        expect(@marge.children.length).to eq 0
      end

      it "Marge should have no pets" do
        expect(@marge.pets.length).to eq 0
      end


      it "Peter should have three children" do
        expect(@peter.children.length).to eq 3
      end

      it "Peter should have no pets" do
        expect(@peter.pets.length).to eq 0
      end


      it "Lois should have no children" do
        expect(@lois.children.length).to eq 0
      end

      it "Lois should have one pet" do
        expect(@lois.pets.length).to eq 1
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
        expect(@peter.children.length).to eq 1
        expect(Child.find_by_key(@peter.id, @meg.guid)).to eq nil
        expect(Child.find_by_key(@peter.id, @chris.guid)).to eq @chris
        expect(Child.find_by_key(@peter.id, @stewie.guid)).to eq nil
      end
    end


    describe "destroying:" do

      it "children should implement dependent: destroy" do
        expect(Child.count).to eq 6
        expect(@homer).to receive(:map_children).with(Child).and_call_original
        @homer.destroy
        expect { @homer.reload(consistent: true) }.to raise_error(OceanDynamo::RecordNotFound)
        expect { @bart.reload(consistent: true) }.to raise_error(OceanDynamo::RecordNotFound)
        expect { @lisa.reload(consistent: true) }.to raise_error(OceanDynamo::RecordNotFound)
        expect { @maggie.reload(consistent: true) }.to raise_error(OceanDynamo::RecordNotFound)
        expect(Child.count).to eq 3
        expect(@peter).to receive(:map_children).with(Child).and_call_original
        @peter.destroy
        expect { @peter.reload(consistent: true) }.to raise_error(OceanDynamo::RecordNotFound)
        expect { @meg.reload(consistent: true) }.to raise_error(OceanDynamo::RecordNotFound)
        expect { @chris.reload(consistent: true) }.to raise_error(OceanDynamo::RecordNotFound)
        expect { @stewie.reload(consistent: true) }.to raise_error(OceanDynamo::RecordNotFound)
        expect(Child.count).to eq 0
      end

      it "cars should implement dependent: :delete" do
        expect(Car.count).to eq 2
        expect(@marge).to receive(:delete_children).with(Car).and_call_original
        expect(@marge).not_to receive(:map_children).with(Car)
        @marge.destroy
        expect { @volvo.reload(consistent: true) }.to raise_error(OceanDynamo::RecordNotFound)
        expect { @saab.reload(consistent: true) }.to raise_error(OceanDynamo::RecordNotFound)
        expect(Car.count).to eq 0
      end

      it "pets should implement dependent: :nullify" do
        expect(Pet.count).to eq 1
        @lois.destroy
        expect(Pet.count).to eq 1
        expect { @brian.reload(consistent: true) }.to raise_error(OceanDynamo::RecordNotFound)
        expect(Pet.find("NULL", @brian.range_key)).to be_a Pet
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


