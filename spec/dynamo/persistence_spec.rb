require 'spec_helper'


describe CloudModel do

  before :all do
    CloudModel.establish_db_connection
  end

  before :each do
    @i = CloudModel.new
  end



  it "should have a predicate destroyed?" do
    @i.destroyed?.should == false
  end

  it "should have a predicate new_record?" do
    @i.new_record?.should == true
  end


  it "should have a predicate persisted?" do
    @i.persisted?.should == false
  end

  it "persisted? should return false when the instance is new" do
    @i.persisted?.should == false
  end

  it "persisted? should return true when the instance is neither new nor destroyed" do
    @i.persisted?.should == false
    @i.save!
    @i.persisted?.should == true
  end

  it "persisted? should return false when the instance has been deleted" do
    @i.persisted?.should == false
    @i.destroy
    @i.persisted?.should == false
  end


  it "should have a method reload" do
    @i.update_attributes gratuitous_float: 3333.3333
    @i.gratuitous_float.should == 3333.3333
    @i.gratuitous_float = 0.0
    @i.reload(consistent: true).should == @i
    @i.gratuitous_float.should == 3333.3333
  end


  it "serialize_attribute should barf on an unknown attribute type" do
    expect { @i.serialize_attribute :quux, 42, {type: :falafel, target_class: Object, no_save: false} }. 
      to raise_error(OceanDynamo::UnsupportedType, "falafel")
  end


  it "create_or_update should call create if the record is new" do
    CloudModel.any_instance.should_receive(:new_record?).and_return(true)
    @i.should_receive(:create)
    @i.create_or_update.should == true
  end

  it "create_or_update should call update if the record already exists" do
    CloudModel.any_instance.should_receive(:new_record?).and_return(false)
    @i.should_receive(:update)
    @i.create_or_update.should == true
  end

  it "save should call create_or_update and return true" do
    @i.should_receive(:create_or_update).and_return(true)
    @i.save.should == true
  end

  it "save should call create_or_update and return false if RecordInvalid is raised" do
    @i.stub(:create_or_update).and_raise(OceanDynamo::RecordInvalid.new(@i))
    @i.save.should == false
  end

  it "save should call create_or_update and return false if RecordInvalid is raised" do
    @i.stub(:create_or_update).and_raise(OceanDynamo::RecordInvalid.new(@i))
    @i.save.should == false
  end

  it "save! should raise RecordNotSaved if the record wasn't saved" do
    @i.stub(:create_or_update).and_return(false)
    expect { @i.save! }.to raise_error(OceanDynamo::RecordNotSaved)
  end

  it "should set @destroyed when an instance is destroyed" do
    @i.destroyed?.should == false
    @i.destroy
    @i.destroyed?.should == true
  end 

  it "destroy should not attempt to delete a DynamoDB object when the instance hasn't been persisted" do
    @i.dynamo_item.should == nil
    @i.destroy
  end

  it "destroy should attempt to delete a DynamoDB object only if the instance has been persisted" do
    @i.save!
    @i.dynamo_item.should be_an AWS::DynamoDB::Item
    @i.dynamo_item.should_receive(:delete)
    @i.destroy
  end

  it "save should reset @new_record when an instance has been persisted" do
    @i.new_record?.should == true
    @i.save
    @i.new_record?.should == false
  end

  it "should set both timestamp attributes for a new record" do
    @i.send(@i.timestamp_attributes[0]).should == nil
    @i.send(@i.timestamp_attributes[1]).should == nil
    @i.save
    @i.send(@i.timestamp_attributes[0]).should be_a Time
    @i.send(@i.timestamp_attributes[1]).should be_a Time
  end

  it "save should update only the second timestamp attribute for persisted records" do
    @i.save!
    cre = @i.send(@i.timestamp_attributes[0])
    upd = @i.send(@i.timestamp_attributes[0])
    cre.should == upd
    @i.save!
    (@i.send(@i.timestamp_attributes[0])).to_f.should == cre.to_f
    (@i.send(@i.timestamp_attributes[1])).should_not == @i.send(@i.timestamp_attributes[0])
  end

  it "should have a class method create" do
    i = CloudModel.create
    i.persisted?.should == true
  end

  it "should have a class method create!" do
    i = CloudModel.create!
    i.persisted?.should == true
  end

  it "should have a method update_attributes" do
    @i.created_by.should == ""
    @i.finished_at.should == nil
    @i.update_attributes(created_by: "Egon", finished_at: Time.now).should == true
    @i.created_by.should == "Egon"
    @i.finished_at.should be_a Time
  end

  it "update_attributes should not barf on an invalid record" do
    @i.update_attributes(steps: nil).should == false
  end

  it "should have a method update_attributes!" do
    @i.created_by.should == ""
    @i.finished_at.should == nil
    @i.update_attributes!(created_by: "Egon", finished_at: Time.now).should == true
    @i.created_by.should == "Egon"
    @i.finished_at.should be_a Time
  end

  it "update_attributes! should barf on an invalid record" do
    expect { @i.update_attributes!(steps: nil) }.to raise_error
  end

  it "should implement touch" do
    i = CloudModel.new
    i.save!
    ca = i.created_at.to_f
    ua = i.created_at.to_f
    ca.should == ua
    i.touch(:started_at)
    i.started_at.should be_a Time
    i.started_at.to_f.should_not == ca
    i.started_at.to_f.should_not == ua
    i.reload consistent: true
    i.started_at.should be_a Time
    i.started_at.to_f.should_not == ca
    i.started_at.to_f.should_not == ua
  end

  it "touch should raise an exception if the instance is frozen" do
    i = CloudModel.create
    i.freeze
    expect { i.touch }.to raise_error(RuntimeError, "can't modify frozen Hash")
  end


  it "should have an instance method delete" do
    i = CloudModel.create!
    i.delete
    i.destroyed?.should == true
  end


  it "should have a class method delete" do
    i = CloudModel.create!
    CloudModel.delete(i.id).should == true
    i.dynamo_item.exists?.should == false
    CloudModel.delete(i.id).should == false
  end


  it "delete should not raise an exception if the instance is frozen" do
    i = CloudModel.create
    i.freeze
    expect { i.delete }.not_to raise_error
  end

  it "destroy should not raise an exception if the instance is frozen" do
    i = CloudModel.create
    i.freeze
    expect { i.destroy }.not_to raise_error
  end


  it "delete should freeze the model" do
    i = CloudModel.create
    i.should_receive(:freeze)
    i.delete
  end

  it "destroy should freeze the model" do
    i = CloudModel.create
    i.should_receive(:freeze)
    i.destroy
  end

  it "destroy! should freeze the model" do
    i = CloudModel.create
    i.should_receive(:freeze)
    i.destroy!
  end


end
