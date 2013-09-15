require 'spec_helper'


describe CloudModel do

  before :all do
    CloudModel.establish_db_connection
  end


  it "should have an automatically supplied lock_version field" do
    CloudModel.fields.should include :lock_version
  end

  it "should have a default lock_version value of 0" do
    CloudModel.new.lock_version.should == 0
  end


  it "should use optimistic locking in update" do
    uuid = CloudModel.create.uuid
    one = CloudModel.find uuid
    one.lock_version.should == 0
    two = CloudModel.find uuid
    two.lock_version.should == 0
    one.save!
    two.lock_version.should == 0
    one.lock_version.should == 1
    expect { two.save! }.to raise_error(OceanDynamo::StaleObjectError)
    expect { one.save! }.not_to raise_error
  end

  it "should use optimistic locking in destroy" do
    uuid = CloudModel.create.uuid
    one = CloudModel.find uuid
    one.lock_version.should == 0
    two = CloudModel.find uuid
    two.lock_version.should == 0
    one.save!
    two.lock_version.should == 0
    one.lock_version.should == 1
    expect { two.destroy! }.to raise_error(OceanDynamo::StaleObjectError)
    expect { one.destroy! }.not_to raise_error
  end

  it "should use optimistic locking in touch" do
    uuid = CloudModel.create.uuid
    one = CloudModel.find uuid
    one.lock_version.should == 0
    two = CloudModel.find uuid
    two.lock_version.should == 0
    one.save!
    two.lock_version.should == 0
    one.lock_version.should == 1
    expect { two.touch }.to raise_error(OceanDynamo::StaleObjectError)
    expect { one.touch }.not_to raise_error
  end

end
