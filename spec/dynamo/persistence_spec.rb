require 'spec_helper'


describe CloudModel do

  before :all do
    CloudModel.establish_db_connection
  end

  before :each do
    @i = CloudModel.new
  end



  it "should have a predicate destroyed?" do
    expect(@i.destroyed?).to eq false
  end

  it "should have a predicate new_record?" do
    expect(@i.new_record?).to eq true
  end


  it "should have a predicate persisted?" do
    expect(@i.persisted?).to eq false
  end

  it "persisted? should return false when the instance is new" do
    expect(@i.persisted?).to eq false
  end

  it "persisted? should return true when the instance is neither new nor destroyed" do
    expect(@i.persisted?).to eq false
    @i.save!
    expect(@i.persisted?).to eq true
  end

  it "persisted? should return false when the instance has been deleted" do
    expect(@i.persisted?).to eq false
    @i.destroy
    expect(@i.persisted?).to eq false
  end


  it "should have a method reload" do
    @i.update_attributes gratuitous_float: 3333.3333
    expect(@i.gratuitous_float).to eq 3333.3333
    @i.gratuitous_float = 0.0
    expect(@i.reload(consistent: true)).to eq @i
    expect(@i.gratuitous_float).to eq 3333.3333
  end


  it "create_or_update should call create if the record is new" do
    expect_any_instance_of(CloudModel).to receive(:new_record?).and_return(true)
    expect(@i).to receive(:create)
    expect(@i.create_or_update).to eq true
  end

  it "create_or_update should call update if the record already exists" do
    expect_any_instance_of(CloudModel).to receive(:new_record?).and_return(false)
    expect(@i).to receive(:update)
    expect(@i.create_or_update).to eq true
  end

  it "save should call create_or_update and return true" do
    expect(@i).to receive(:create_or_update).and_return(true)
    expect(@i.save).to eq true
  end

  it "save should call create_or_update and return false if RecordInvalid is raised" do
    allow(@i).to receive(:create_or_update).and_raise(OceanDynamo::RecordInvalid.new(@i))
    expect(@i.save).to eq false
  end

  it "save should call create_or_update and return false if RecordInvalid is raised" do
    allow(@i).to receive(:create_or_update).and_raise(OceanDynamo::RecordInvalid.new(@i))
    expect(@i.save).to eq false
  end

  it "save! should raise RecordNotSaved if the record wasn't saved" do
    allow(@i).to receive(:create_or_update).and_return(false)
    expect { @i.save! }.to raise_error(OceanDynamo::RecordNotSaved)
  end

  it "should set @destroyed when an instance is destroyed" do
    expect(@i.destroyed?).to eq false
    @i.destroy
    expect(@i.destroyed?).to eq true
  end 

  it "destroy should not attempt to delete a DynamoDB object when the instance hasn't been persisted" do
    expect(@i.dynamo_item).to eq nil
    @i.destroy
  end

  it "destroy should attempt to delete a DynamoDB object only if the instance has been persisted" do
    @i.save!
    expect(@i.dynamo_item).to be_an AWS::DynamoDB::Item
    expect(@i.dynamo_item).to receive(:delete)
    @i.destroy
  end

  it "save should reset @new_record when an instance has been persisted" do
    expect(@i.new_record?).to eq true
    @i.save
    expect(@i.new_record?).to eq false
  end

  it "should set both timestamp attributes for a new record" do
    expect(@i.send(@i.timestamp_attributes[0])).to eq nil
    expect(@i.send(@i.timestamp_attributes[1])).to eq nil
    @i.save
    expect(@i.send(@i.timestamp_attributes[0])).to be_a Time
    expect(@i.send(@i.timestamp_attributes[1])).to be_a Time
  end

  it "save should update only the second timestamp attribute for persisted records" do
    @i.save!
    cre = @i.send(@i.timestamp_attributes[0])
    upd = @i.send(@i.timestamp_attributes[0])
    expect(cre).to eq upd
    @i.save!
    expect((@i.send(@i.timestamp_attributes[0])).to_f).to eq cre.to_f
    expect(@i.send(@i.timestamp_attributes[1])).not_to eq @i.send(@i.timestamp_attributes[0])
  end

  it "should have a class method create" do
    i = CloudModel.create
    expect(i.persisted?).to eq true
  end

  it "should have a class method create!" do
    i = CloudModel.create!
    expect(i.persisted?).to eq true
  end

  it "should have a method update_attributes" do
    expect(@i.created_by).to eq ""
    expect(@i.finished_at).to eq nil
    expect(@i.update_attributes(created_by: "Egon", finished_at: Time.now)).to eq true
    expect(@i.created_by).to eq "Egon"
    expect(@i.finished_at).to be_a Time
  end

  it "update_attributes should not barf on an invalid record" do
    expect(@i.update_attributes(steps: nil)).to eq false
  end

  it "should have a method update_attributes!" do
    expect(@i.created_by).to eq ""
    expect(@i.finished_at).to eq nil
    expect(@i.update_attributes!(created_by: "Egon", finished_at: Time.now)).to eq true
    expect(@i.created_by).to eq "Egon"
    expect(@i.finished_at).to be_a Time
  end

  it "update_attributes! should barf on an invalid record" do
    expect { @i.update_attributes!(steps: nil) }.to raise_error OceanDynamo::RecordInvalid
  end

  it "should implement touch" do
    i = CloudModel.new
    i.save!
    ca = i.created_at.to_f
    ua = i.created_at.to_f
    expect(ca).to eq ua
    i.touch(:started_at)
    expect(i.started_at).to be_a Time
    expect(i.started_at.to_f).not_to eq ca
    expect(i.started_at.to_f).not_to eq ua
    i.reload consistent: true
    expect(i.started_at).to be_a Time
    expect(i.started_at.to_f).not_to eq ca
    expect(i.started_at.to_f).not_to eq ua
  end

  it "touch should raise an exception if the instance is frozen" do
    i = CloudModel.create
    i.freeze
    expect { i.touch }.to raise_error(RuntimeError, "can't modify frozen Hash")
  end


  it "should have an instance method delete" do
    i = CloudModel.create!
    i.delete
    expect(i.destroyed?).to eq true
  end


  it "should have a class method delete" do
    i = CloudModel.create!
    expect(CloudModel.delete(i.id)).to eq true
    expect(i.dynamo_item.exists?).to eq false
    expect(CloudModel.delete(i.id)).to eq false
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
    expect(i).to receive(:freeze)
    i.delete
  end

  it "destroy should freeze the model" do
    i = CloudModel.create
    expect(i).to receive(:freeze)
    i.destroy
  end

  it "destroy! should freeze the model" do
    i = CloudModel.create
    expect(i).to receive(:freeze)
    i.destroy!
  end


  describe "delete_all" do

    before :each do
      CloudModel.establish_db_connection
      CloudModel.all.each(&:delete)
    end


    it "should implement delete_all" do
      CloudModel.delete_all
    end
  
    it "should remove all items" do
      CloudModel.create!
      CloudModel.create!
      CloudModel.create!
      expect(CloudModel.count).to eq 3
      CloudModel.delete_all      
      expect(CloudModel.count).to eq 0
    end
  end


  describe "destroy_all" do

    before :each do
      CloudModel.establish_db_connection
      CloudModel.delete_all
    end


    it "should implement destroy_all" do
      CloudModel.destroy_all
    end

    it "should remove all items" do
      CloudModel.create!
      CloudModel.create!
      CloudModel.create!
      expect(CloudModel.count).to eq 3
      CloudModel.destroy_all      
      expect(CloudModel.count).to eq 0
    end
  end

end
