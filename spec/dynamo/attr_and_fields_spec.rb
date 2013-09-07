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
    CloudModel.table_range_key.should == false
  end

  it "should barf on a missing primary key at instantiation" do
     expect { CloudModel.new }.not_to raise_error
     CloudModel.table_hash_key = false
     expect { CloudModel.new }.to raise_error
     CloudModel.table_hash_key = :uuid   # We restore the expected value, as classes aren't reloaded between tests
  end


  it "should be possible to refer to the hash_key field using #id, regardless of its name" do
    i = CloudModel.new uuid: "blahonga"
    i.uuid.should == "blahonga"
    i.id.should == "blahonga"
  end

  it "should be possible to set the hash_key field using #id, regardless of its name" do
    i = CloudModel.new uuid: "blahonga"
    i.id.should == "blahonga"
    i.id = "snyko"
    i.uuid.should == "snyko"
  end

  it "should assign an UUID to the hash_key field if nil at create" do
    i = CloudModel.new uuid: nil
    i.save.should == true
    i.uuid.should_not == nil
  end


  it "should have a class method read_capacity_units to set the table_read_capacity_units class attr" do
    CloudModel.table_read_capacity_units.should == 10
    CloudModel.read_capacity_units(111).should == 111
    CloudModel.table_read_capacity_units.should == 111
    CloudModel.table_read_capacity_units = 10           # Restore
  end

  it "table_read_capacity_units should default to 10" do
    CloudModel.table_read_capacity_units.should == 10
  end


  it "should have a class method write_capacity_units to set the table_write_capacity_units class attr" do
    CloudModel.table_write_capacity_units.should == 5
    CloudModel.write_capacity_units(222).should == 222
    CloudModel.table_write_capacity_units.should == 222
    CloudModel.table_write_capacity_units = 5           # Restore
  end

  it "table_write_capacity_units should default to 5" do
    CloudModel.table_write_capacity_units.should == 5
  end
  


  it "class should have an automatically supplied created_at field" do
    CloudModel.fields.should include :created_at
  end

  it "class should have an automatically supplied updated_at field" do
    CloudModel.fields.should include :updated_at
  end


  it "should have a :token field" do
    CloudModel.fields.should include :token
  end

  it "should have :token field with a defaulted type of String" do
    CloudModel.fields[:token][:type].should == :string
  end

  it "should have a :steps field with a type of :serialized and a :default of []" do
    CloudModel.fields[:steps][:type].should == :serialized
    CloudModel.fields[:steps][:default].should == []
  end


  it "should define accessors for all automatically defined fields" do
    i = CloudModel.new
    i.should respond_to :created_at
    i.should respond_to :created_at=
  end

  it "should define accessors for all declared fields" do
    i = CloudModel.new
    i.should respond_to :uuid
    i.should respond_to :uuid=
  end

  it "should allow fields to be read and written" do
    i = CloudModel.new
    i.token.should == ""
    i.token = "foo"
    i.token.should == "foo"
  end

  it "should have a method assign_attributes" do
    i = CloudModel.new
    i.assign_attributes token: "changed", default_poison_limit: 10
    i.token.should == "changed"
    i.default_poison_limit.should == 10
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

  it "should verify that structure isn't shared in defaults between instances" do
    i = CloudModel.new
    i.list.should == [1, 2, 3]
    i.list << 4
    i.list.should == [1, 2, 3, 4]

    j = CloudModel.new
    j.list.should == [1, 2, 3]
    j.list << 4
    j.list.should == [1, 2, 3, 4]
  end


  describe "string attributes" do
    describe "without defaults" do
      describe "before create" do

        it 'should default to the empty string' do
          CloudModel.new.token.should == ""
        end

        it "should be able to receive any init value" do
          CloudModel.new(token: nil).token.should == nil
          CloudModel.new(token: "Edwin").token.should == "Edwin"
          CloudModel.new(token: 3.14).token.should == 3.14
        end

        it "unknown fields should not be stored at all" do
          i = CloudModel.new(quux: 23, flouf: "nyx", blipp: nil, token: "store me")
          i.attributes.keys.should == i.fields.keys
          i.attributes.keys.should == [
            "created_at", 
            "updated_at", 
            "lock_version", 
            "uuid", 
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
            "list"
          ]
          i.token.should == "store me"
        end
      end

      describe "after instantiation" do

        it "should return a stored value" do
          i = CloudModel.create token: "hey"
          i.token.should == "hey"
          i.reload
          i.token.should == "hey"
          CloudModel.find(i.uuid, consistent: true).token.should == "hey"
        end

        it "should return a stored empty string" do
          i = CloudModel.create token: ""
          i.token.should == ""
          i.reload
          i.token.should == ""
          CloudModel.find(i.uuid, consistent: true).token.should == ""
        end
      end
    end

    describe "with defaults" do
      describe "before create" do

        it 'should be assigned the default' do
          CloudModel.new.credentials.should == "blah"
        end

        it "should be able to receive any init value" do
          CloudModel.new(credentials: nil).credentials.should == nil
          CloudModel.new(credentials: "Edwin").credentials.should == "Edwin"
          CloudModel.new(credentials: 3.14).credentials.should == 3.14
        end
      end

      describe "after instantiation" do

        it "should return a stored value" do
          i = CloudModel.create credentials: "hey"
          i.credentials.should == "hey"
          i.reload
          i.credentials.should == "hey"
          CloudModel.find(i.uuid, consistent: true).credentials.should == "hey"
        end

        it "should return a stored empty string" do
          i = CloudModel.create credentials: ""
          i.credentials.should == ""
          i.reload
          i.credentials.should == ""
          CloudModel.find(i.uuid, consistent: true).credentials.should == ""
        end

        it "should return a stored nil as the empty string" do
          i = CloudModel.create credentials: nil
          i.credentials.should == nil
          i.reload
          i.credentials.should == ""
          CloudModel.find(i.uuid, consistent: true).credentials.should == ""
        end
      end
    end


  end
end
