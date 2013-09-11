require 'spec_helper'

describe Voom do

  before :each do
    @i = Voom.new
  end


  it "should do instantiation callbacks in the correct order" do
    @i.valid?
    @i.logged.should == [
      "after_initialize", 
      "before_validation", 
      "after_validation"
    ]
  end

  it "should do save callbacks in the correct order" do
    @i.save!
    @i.logged.should == [
      "after_initialize", 
      "before_validation", 
      "after_validation", 
      "before_save", 
      "before_create", 
      "after_create", 
      "after_save", 
      "after_commit"
    ]
  end

  it "should do update callbacks in the correct order" do
    @i.save!
    @i.logged = []
    @i.save!
    @i.logged.should == [
      "before_validation", 
      "after_validation", 
      "before_save", 
      "before_update", 
      "after_update", 
      "after_save", 
      "after_commit"
    ]
  end

  it "should do destroy callbacks in the correct order" do
    @i.save!
    @i.logged = []
    @i.destroy
    @i.logged.should == [
      "before_destroy", 
      "after_destroy", 
      "after_commit"
    ]
  end

  # it "should do find callbacks in the correct order" do
  #   @i.save!
  #   @i.logged = []
  #   Voom.find(@i.id, consistent: true).logged.should == [
  #     "after_find", 
  #     "after_initialize", 
  #   ]
  # end


  it "should do touch callbacks in the correct order" do
    @i.save!
    @i.logged = []
    @i.touch
    @i.logged.should == [
      "before_touch", 
      "after_touch"
    ]
  end


  it "destroy! should not raise an exception for an unpersisted record" do
    expect { @i.destroy! }.not_to raise_exception
  end


  it "destroy! should raise an exception if a before callback cancelled the destroy" do
    @i.no_destroy = true
    @i.save!
    expect { @i.destroy! }.to raise_exception(OceanDynamo::RecordNotDestroyed)
  end



end

