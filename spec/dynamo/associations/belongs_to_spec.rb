require 'spec_helper'


class Master < OceanDynamo::Table
  dynamo_schema(create: true, table_name_suffix: Api.basename_suffix) do
    attribute :name
  end
  has_many :slaves
end


class Slave < OceanDynamo::Table
  dynamo_schema(:guid, create: true, table_name_suffix: Api.basename_suffix) do
    attribute :name
  end
  belongs_to :master
  has_many :subslaves
end


class Subslave < OceanDynamo::Table
  dynamo_schema(:guid, create: true, table_name_suffix: Api.basename_suffix) do
    attribute :name
  end
  belongs_to :slave, composite_key: true
end


class Other < OceanDynamo::Table
end



describe Slave do

  before :all do
    Master.establish_db_connection
    Slave.establish_db_connection
    Subslave.establish_db_connection
  end

  before :each do
    @m = Master.create!
  end


  it "should handle a parent table with a composite key" do
    s = Slave.create! master: @m
    ss = Subslave.create! slave: s
    expect(ss.slave).to eq s
  end


  it "should barf on an explicitly specified range key" do
    expect { 
      class IllegalOne < OceanDynamo::Table
        dynamo_schema(:good, :not_so_good) do
        end
        belongs_to :something
      end
    }.to raise_error(OceanDynamo::RangeKeyMustNotBeSpecified, 
                     "Tables with belongs_to relations may not specify a range key")
  end


  it "should barf on a hash key called :id" do
    expect { 
      class IllegalOne < OceanDynamo::Table
        dynamo_schema() do
        end
        belongs_to :something
      end
    }.to raise_error(OceanDynamo::HashKeyMayNotBeNamedId, 
                     "Tables with belongs_to relations may not name their hash key :id")
  end


  it "should have a range key named :guid" do
    expect(Slave.table_range_key).to eq :guid
  end

  it "should have a hash key named :master_id" do
    expect(Slave.table_hash_key).to eq :master_id
  end


  it "should have a :guid attribute" do
    expect(Slave.fields).to include :guid
    i = Slave.new
    expect(i.guid).to eq ""            # String because it's an empty guid
    i.guid = "2345"
    expect(i[:guid]).to eq "2345"
  end

  it "should not have a :master attribute" do
    expect(Slave.fields).not_to include :master
  end

  it "should have a :master_id attribute" do
    expect(Slave.fields).to include :master_id
    i = Slave.new
    expect(i.master_id).to eq nil      # nil because it's an empty reference
    i.master_id = "the-master-id"
    expect(i[:master_id]).to eq "the-master-id"
  end


  it "should have a :master_id attribute with target_class: Master" do
    expect(Slave.fields[:master_id][:target_class]).to eq Master
  end

  it "should not have the target_class setting on any other attributes" do
    expect(Slave.fields[:name][:target_class]).to eq nil
  end


  it "the :id reader should read the :master_id attribute" do
    i = Slave.new
    i.master_id = "hash key"
    expect(i.attributes).to eq({
      "guid"=>"", 
      "created_at"=>nil, 
      "updated_at"=>nil, 
      "lock_version"=>0, 
      "name"=>"", 
      "master_id"=>"hash key"
    })
    expect(i[:master_id]).to eq "hash key"
    expect(i.id).to eq "hash key"
    expect(i[:id]).to eq "hash key"
  end

  it "the :id writer should set the :master_id attribute" do
    i = Slave.new
    i.id = "I'm the ID now"
    expect(i.attributes).to eq({
      "guid"=>"", 
      "created_at"=>nil, 
      "updated_at"=>nil, 
      "lock_version"=>0, 
      "name"=>"", 
      "master_id"=>"I'm the ID now"
    })
  end

  it "the :master_id reader should read the :master_id attribute" do
    i = Slave.new
    i.master_id = "range key"
    expect(i.attributes).to eq({
      "guid"=>"", 
      "created_at"=>nil, 
      "updated_at"=>nil, 
      "lock_version"=>0, 
      "name"=>"", 
      "master_id"=>"range key"
    })
    expect(i.master_id).to eq "range key"
    expect(i[:master_id]).to eq "range key"
  end



  it "instances should be instantiatable" do
    Slave.create! master: @m
  end

  it "instances should be reloadable" do
    s = Slave.create! master: @m
    s.reload
  end

  it "instances should be touchable" do
    s = Slave.create! master: @m
    s.touch
  end


  it "a new instance should have nil in the assocation attr" do
    expect(Slave.new.master).to eq nil
  end

  it "a new instance should have nil in attr_id" do
    expect(Slave.new.master_id).to eq nil
  end


  it "a saved instance should not have nil in the assocation attr" do
    expect(Slave.create!(master:@m).master).not_to eq nil
  end

  it "a saved instance should not have nil in attr_id" do
    expect(Slave.create!(master: @m).master_id).not_to eq nil
  end


  it "a reloaded instance should not have nil in the assocation attr" do
    expect(Slave.create!(master: @m).reload.master).not_to eq nil
  end

  it "a reloaded instance should not have nil in attr_id" do
    expect(Slave.create!(master: @m).reload.master_id).not_to eq nil
  end


  it "attr_id should be directly assignable" do
    s = Slave.new
    s.master_id = "some-guid"
    expect(s.master_id).to eq "some-guid"
    expect(s.instance_variable_get(:@master)).to eq nil
  end

  it "attr_id should be mass-assignable" do
    s = Slave.new master_id: "a-guid"
    expect(s.master_id).to eq "a-guid"
    expect(s.instance_variable_get(:@master)).to eq nil
  end

  it "attr should be directly assignable" do
    s = Slave.new
    s.master = @m
    expect(s.instance_variable_get(:@master)).to eq @m
    expect(s.master).to eq @m
    expect(s.master_id).to be_a String
    expect(s.master_id).to eq @m.id
  end

  it "attr should be mass-assignable" do
    s = Slave.new master: @m
    expect(s.instance_variable_get(:@master)).to eq @m
    expect(s.master).to eq @m
    expect(s.master_id).to be_a String
    expect(s.master_id).to eq @m.id
  end


  it "attr should be able to be mass-assigned an instance of the associated type" do
    s = Slave.new master: @m
    expect(s.master).to eq @m
  end


  it "an instance in attr must be of the correct target class" do
    wrong = Slave.create!(master: @m)
    expect { Slave.create master: wrong }.
      to raise_error(OceanDynamo::AssociationTypeMismatch, "can't save a Slave in a Master foreign key")
  end

  it "should barf on an instance in attr_id" do
    wrong = Slave.create!(master_id: @m.id)
    expect { Slave.create master_id: wrong }.
      to raise_error(StandardError, "Foreign key master_id must be nil or a string")
  end

  it "the attr, if it contains an instance, should load and return that instance when accessed after a save" do
    s = Slave.create! master: @m
    expect(s.master).to eq @m
    s.reload
    expect(s.master).to eq @m
  end

  it "attr load should barf on an unknown key" do
    s = Slave.create! master_id: "whatevah"
    expect { s.master }.to raise_error(OceanDynamo::RecordNotFound, 
                                       "can't find a Master with primary key ['whatevah', nil]")
  end

  it "the attr shouldn't be persisted, only the attr_id" do
    s = Slave.create! master: @m
    expect(s.send(:serialized_attributes)['master_id']).to be_a String
    expect(s.send(:serialized_attributes)['master']).to eq nil
  end

  it "the attr should be cached" do
    s = Slave.create! master: @m
    s.reload
    expect(Master).to receive(:find).once.and_return @m
    expect(s.master).to eq @m
    expect(s.master).to eq @m
    expect(s.master).to eq @m
  end


  it "must not allow more than one belongs_to association per model" do
    expect { Slave.belongs_to :other }.
      to raise_error(OceanDynamo::AssociationMustBeUnique, 
                     "Slave already belongs_to Master")
  end


  it "should define build_master" do
    m = Slave.build_master name: "Betty"
    expect(m).to be_a Master
    expect(m.persisted?).not_to eq true
    expect(m.name).to eq "Betty"
    m.save!
  end

  it "should define create_master" do
    m = Slave.create_master name: "White"
    expect(m).to be_a Master
    expect(m.persisted?).to eq true
    expect(m.name).to eq "White"
  end
end
