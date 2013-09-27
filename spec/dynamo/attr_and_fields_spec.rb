require 'spec_helper'


describe CloudModel do

  before :all do
    CloudModel.establish_db_connection
  end


  it_should_behave_like "ActiveModel"

  it "should be instantiatable" do
    CloudModel.new.should be_a CloudModel
  end


  it "should have a class method table_hash_key" do
    CloudModel.table_hash_key.should == :uuid
  end

  it "should have a class method table_range_key" do
    CloudModel.table_range_key.should == nil
  end

  it "should barf on a missing primary key at instantiation" do
     expect { CloudModel.new }.not_to raise_error
     CloudModel.table_hash_key = false
     expect { CloudModel.new }.to raise_error
     CloudModel.table_hash_key = :uuid   # We restore the expected value, as classes aren't reloaded between tests
  end


  it "should be possible to refer to the hash_key attribute using #id, regardless of its name" do
    i = CloudModel.new uuid: "blahonga"
    i.uuid.should == "blahonga"
    i.id.should == "blahonga"
    i[:uuid].should == "blahonga"
    i[:id].should == "blahonga"
  end

  it "should be possible to set the hash_key attribute using #id, regardless of its name" do
    i = CloudModel.new uuid: "blahonga"
    i.id.should == "blahonga"
    i.id = "snyko"
    i.uuid.should == "snyko"
    i.uuid = "moose"
    i.id.should == "moose"
    i[:uuid] = "elk"
    i.uuid.should == "elk"
    i[:id] = "badger"
    i.id.should == "badger"
    i.id.should == i.uuid
    i[:id].should == i[:uuid]
  end

  it "should assign an UUID to the hash_key attribute if nil at create" do
    i = CloudModel.new uuid: nil
    i.save.should == true
    i.uuid.should_not == nil
  end


  it "should define accessors for all attributes, both explicit and implicit" do
    i = CloudModel.new
    i.attributes.keys.should == [
      "uuid", 
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
    i.attributes.keys.should == i.fields.keys
    i.attributes.keys.should include 'token' 
    i.attributes.keys.should_not include 'quux' 
    i.attributes.keys.should_not include 'flouf' 
    i.token.should == "store me"
  end


  it "should allow fields to be read and written" do
    i = CloudModel.new
    i.token.should == ""
    i.token = "foo"
    i.token.should == "foo"
  end

  it "should define an xxxxx? method for each attribute" do
    i = CloudModel.new
    i.token = ""  # This is already the default, this is for clarity
    i.token?.should == false
    i.token = "foo"
    i.token?.should == true
  end

  it "should implement assign_attributes" do
    i = CloudModel.new
    i.assign_attributes token: "changed", default_poison_limit: 10
    i.token.should == "changed"
    i.default_poison_limit.should == 10
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
      i.token.should == "changed"
      i.default_poison_limit.should == 10
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
    i = CloudModel.new uuid: "Barack-Obladiobladama", created_by: "http://somewhere"
    i.uuid.should == "Barack-Obladiobladama"
    i.created_by.should == "http://somewhere"
  end

  it "should set defaults for field values not supplied in the call to new" do
    i = CloudModel.new
    i.default_poison_limit.should == 5
  end


  it "should require the uuid to be present" do
    CloudModel.new(steps: nil).valid?.should == false
    CloudModel.new(steps: [1,2,3]).valid?.should == true
  end


  it "should have an attribute reader with as many elements as there are fields" do
    CloudModel.new.attributes.length.should == CloudModel.fields.length
  end

  it "should not have an attributes writer" do
    expect { CloudModel.new.attributes = {} }.to raise_error
  end

  it "should have string keys" do
    CloudModel.new.attributes.should include 'uuid'
    CloudModel.new.attributes.should include 'created_at'
  end


  it "to_key should return nil when the instance hasn't been persisted" do
    CloudModel.any_instance.should_receive(:persisted?).and_return(false)
    CloudModel.new.to_key.should == nil
  end

  it "to_key should return an array of the present index key when the instance has been persisted" do
    CloudModel.any_instance.should_receive(:persisted?).and_return(true)
    i = CloudModel.create
    i.to_key.should == [i.uuid]
  end

  it "@i[:foo] and @i['foo'] should be equivalent to @i.foo" do
    i = CloudModel.new uuid: "trala"
    i[:uuid].should == "trala"
    i['uuid'].should == "trala"
  end

  it "@i[:foo]= and @i['foo']= should be equivalent to @i.foo=" do
    i = CloudModel.new uuid: "trala"
    i[:uuid] = "wow"
    i[:uuid].should == "wow"
    i['uuid'] = "yowza"
    i['uuid'].should == "yowza"
  end

  it "should verify that << works normally" do
    x = [:foo, :bar, :baz]
    x.should == [:foo, :bar, :baz]
    x << :quux
    x.should == [:foo, :bar, :baz, :quux]
    y = []
    y.should == []
    y << :nix
    y.should == [:nix]
    z = []
    z.should == []
    z << :nix
    z.should == [:nix]
  end

  it "shouldn't share attribute structure between instances" do
    i = CloudModel.new
    i.list.should == ["1", "2", "3"]
    i.list << "4"
    i.list.should == ["1", "2", "3", "4"]

    j = CloudModel.new
    j.list.should == ["1", "2", "3"]
    j.list << "4"
    j.list.should == ["1", "2", "3", "4"]
  end

  it "should implement freeze" do
    i = CloudModel.new
    i.freeze
    i.token.should == ""
    expect { i.token = "Hey, mister!" }.to raise_error(RuntimeError, "can't modify frozen Hash")
  end

  it "write_attribute should raise an exception if the attribute is unknown" do
    i = CloudModel.new
    expect { i.write_attribute :you_wish, 123 }.to raise_error(ActiveModel::MissingAttributeError, 
                                                               "can't write unknown attribute 'you_wish'")
  end

  it "_assign_attribute should call write_attribute" do
    i = CloudModel.create!
    i.should_receive(:_assign_attribute).with("token", "hey")
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
    a.should_not == b
    a.save!
    b.save!
    a.should_not == b
    c = CloudModel.find(a.uuid)
    c.should == a
    c.should_not == b
  end

  it "implement the <=> to allow for sorting" do
    a = CloudModel.create!
    b = CloudModel.create!
    (a <=> b).should be_an Integer
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

end


