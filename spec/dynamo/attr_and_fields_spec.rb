require 'spec_helper'


describe CloudModel do

  before :all do
    CloudModel.establish_db_connection
  end


  it_should_behave_like "ActiveModel"

  it "should be instantiatable" do
    expect(CloudModel.new).to be_a CloudModel
  end


  it "should have a class method table_hash_key" do
    expect(CloudModel.table_hash_key).to eq :guid
  end

  it "should have a class method table_range_key" do
    expect(CloudModel.table_range_key).to eq nil
  end

  it "should barf on a missing primary key at instantiation" do
     expect { CloudModel.new }.not_to raise_error
     CloudModel.table_hash_key = false
     expect { CloudModel.new }.to raise_error OceanDynamo::UnknownPrimaryKey
     CloudModel.table_hash_key = :guid   # We restore the expected value, as classes aren't reloaded between tests
  end


  it "should be possible to refer to the hash_key attribute using #id, regardless of its name" do
    i = CloudModel.new guid: "blahonga"
    expect(i.guid).to eq "blahonga"
    expect(i.id).to eq "blahonga"
    expect(i[:guid]).to eq "blahonga"
    expect(i[:id]).to eq "blahonga"
  end

  it "should be possible to set the hash_key attribute using #id, regardless of its name" do
    i = CloudModel.new guid: "blahonga"
    expect(i.id).to eq "blahonga"
    i.id = "snyko"
    expect(i.guid).to eq "snyko"
    i.guid = "moose"
    expect(i.id).to eq "moose"
    i[:guid] = "elk"
    expect(i.guid).to eq "elk"
    i[:id] = "badger"
    expect(i.id).to eq "badger"
    expect(i.id).to eq i.guid
    expect(i[:id]).to eq i[:guid]
  end

  it "should assign a UUID to the hash_key attribute if nil at create" do
    i = CloudModel.new guid: nil
    expect(i.save).to eq true
    expect(i.guid).not_to eq nil
  end


  it "should define accessors for all attributes, both explicit and implicit" do
    i = CloudModel.new
    expect(i.attributes.keys).to eq [
      "guid", 
      "created_at", 
      "updated_at", 
      "lock_version", 
      "credentials", 
      "token", 
      "steps", 
      "max_seconds_in_queue", 
      "default_poison_limit", 
      "default_step_time", 
      "created_by", 
      "updated_by", 
      "destroy_at", 
      "started_at", 
      "last_completed_step", 
      "succeeded", 
      "failed", 
      "poison", 
      "finished_at", 
      "gratuitous_float", 
      "zalagadoola", 
      "list",
      "int"
    ]
  end

  it "undeclared attributes should not be stored at all" do
    i = CloudModel.new(quux: 23, flouf: "nyx", blipp: nil, token: "store me")
    expect(i.attributes.keys).to eq i.fields.keys
    expect(i.attributes.keys).to include 'token' 
    expect(i.attributes.keys).not_to include 'quux' 
    expect(i.attributes.keys).not_to include 'flouf' 
    expect(i.token).to eq "store me"
  end


  it "should allow fields to be read and written" do
    i = CloudModel.new
    expect(i.token).to eq ""
    i.token = "foo"
    expect(i.token).to eq "foo"
  end

  it "should define an xxxxx? method for each attribute" do
    i = CloudModel.new
    i.token = ""  # This is already the default, this is for clarity
    expect(i.token?).to eq false
    i.token = "foo"
    expect(i.token?).to eq true
  end

  it "should implement assign_attributes" do
    i = CloudModel.new
    i.assign_attributes token: "changed", default_poison_limit: 10
    expect(i.token).to eq "changed"
    expect(i.default_poison_limit).to eq 10
  end

  it "assign_attributes should take the :without_protection key arg" do
    i = CloudModel.create!
    i.assign_attributes({token: "hey"}, without_protection: true)
  end

  it "update_attributes should take the :without_protection key arg" do
    i = CloudModel.create!
    i.update_attributes({token: "hey"}, without_protection: true)
  end

  it "update_attributes! should take the :without_protection key arg" do
    i = CloudModel.create!
    i.update_attributes!({token: "hey"}, without_protection: true)
  end



  describe "ActiveModel::ForbiddenAttributesError" do

    it "should be raised by assign_attributes if the passed hash responds to permitted? method and the return value of this method is false" do
      i = CloudModel.new
      args = {token: "changed", default_poison_limit: 10}
      i.assign_attributes args
      expect(i.token).to eq "changed"
      expect(i.default_poison_limit).to eq 10
    end

    # it "blahonga" do
    #   i = CloudModel.new
    #   args = ActionController::Parameters.new(token: "changed", default_poison_limit: 10).
    #     require(:token).permit(:default_poison_limit)
    #   args.permitted?
    #   i.assign_attributes args
    #   i.token.should == "changed"
    #   i.default_poison_limit.should == 10
    # end
  end



  it "should assign the fields values supplied in the call to new" do
    i = CloudModel.new guid: "Barack-Obladiobladama", created_by: "http://somewhere"
    expect(i.guid).to eq "Barack-Obladiobladama"
    expect(i.created_by).to eq "http://somewhere"
  end

  it "should set defaults for field values not supplied in the call to new" do
    i = CloudModel.new
    expect(i.default_poison_limit).to eq 5
  end


  it "should require the guid to be present" do
    expect(CloudModel.new(steps: nil).valid?).to eq false
    expect(CloudModel.new(steps: [1,2,3]).valid?).to eq true
  end


  it "should have an attribute reader with as many elements as there are fields" do
    expect(CloudModel.new.attributes.length).to eq CloudModel.fields.length
  end

  it "should not have an attributes writer" do
    expect { CloudModel.new.attributes = {} }.to raise_error NoMethodError
  end

  it "should have string keys" do
    expect(CloudModel.new.attributes).to include 'guid'
    expect(CloudModel.new.attributes).to include 'created_at'
  end


  it "to_key should return nil when the instance hasn't been persisted" do
    expect_any_instance_of(CloudModel).to receive(:persisted?).and_return(false)
    expect(CloudModel.new.to_key).to eq nil
  end

  it "to_key should return an array of the present index key when the instance has been persisted" do
    expect_any_instance_of(CloudModel).to receive(:persisted?).and_return(true)
    i = CloudModel.create
    expect(i.to_key).to eq [i.guid]
  end

  it "@i[:foo] and @i['foo'] should be equivalent to @i.foo" do
    i = CloudModel.new guid: "trala"
    expect(i[:guid]).to eq "trala"
    expect(i['guid']).to eq "trala"
  end

  it "@i[:foo]= and @i['foo']= should be equivalent to @i.foo=" do
    i = CloudModel.new guid: "trala"
    i[:guid] = "wow"
    expect(i[:guid]).to eq "wow"
    i['guid'] = "yowza"
    expect(i['guid']).to eq "yowza"
  end

  it "should verify that << works normally" do
    x = [:foo, :bar, :baz]
    expect(x).to eq [:foo, :bar, :baz]
    x << :quux
    expect(x).to eq [:foo, :bar, :baz, :quux]
    y = []
    expect(y).to eq []
    y << :nix
    expect(y).to eq [:nix]
    z = []
    expect(z).to eq []
    z << :nix
    expect(z).to eq [:nix]
  end

  it "shouldn't share attribute structure between instances" do
    i = CloudModel.new
    expect(i.list).to eq ["1", "2", "3"]
    i.list << "4"
    expect(i.list).to eq ["1", "2", "3", "4"]

    j = CloudModel.new
    expect(j.list).to eq ["1", "2", "3"]
    j.list << "4"
    expect(j.list).to eq ["1", "2", "3", "4"]
  end

  it "should implement freeze" do
    i = CloudModel.new
    i.freeze
    expect(i.token).to eq ""
    expect { i.token = "Hey, mister!" }.to raise_error(RuntimeError, "can't modify frozen Hash")
  end

  it "write_attribute should raise an exception if the attribute is unknown" do
    i = CloudModel.new
    expect { i.write_attribute :you_wish, 123 }.to raise_error(ActiveModel::MissingAttributeError, 
                                                               "can't write unknown attribute 'you_wish'")
  end

  it "_assign_attribute should call write_attribute" do
    i = CloudModel.create!
    expect(i).to receive(:_assign_attribute).with("token", "hey")
    i.assign_attributes(token: "hey")
  end

  it "_assign_attribute should barf on unknown attributes" do
    i = CloudModel.create!
    expect { i.assign_attributes(outlandish: "indeed") }.to raise_error(OceanDynamo::UnknownAttributeError,
                                                                        "unknown attribute: 'outlandish'")
  end

  it "implement the == operator for OceanDynamo instances" do
    a = CloudModel.new
    b = CloudModel.new
    expect(a).not_to eq b
    a.save!
    b.save!
    expect(a).not_to eq b
    c = CloudModel.find(a.guid)
    expect(c).to eq a
    expect(c).not_to eq b
  end

  it "implement the <=> to allow for sorting" do
    a = CloudModel.create!
    b = CloudModel.create!
    expect(a <=> b).to be_an Integer
  end


  it "should raise a DangerousAttributeError when an attribute name exists in the namespace" do
    expect {
      class Pericoloso < OceanDynamo::Table
        dynamo_schema(connect: false, create: false) do
          attribute :new
        end
      end
    }.to raise_error(OceanDynamo::DangerousAttributeError,
                     "new is defined by OceanDynamo")
    expect {
      class Pericoloso < OceanDynamo::Table
        dynamo_schema(connect: false, create: false) do
          attribute :belongs_to
        end
      end
    }.to raise_error(OceanDynamo::DangerousAttributeError,
                     "belongs_to is defined by OceanDynamo")
  end

  it "should convert string dates when assigning them to a datetime attribute" do
    i = CloudModel.new 
    i.destroy_at = "2015-12-09T21:37:00Z"
    expect(i.destroy_at).to be_a Time
    i.save!
    i.reload
    expect(i.destroy_at).to be_a Time
  end

end


