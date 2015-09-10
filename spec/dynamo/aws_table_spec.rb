require 'spec_helper'


describe CloudModel do

  before :all do
    CloudModel.establish_db_connection
  end

  before :each do
    CloudModel.dynamo_client = nil
    CloudModel.dynamo_table = nil
    CloudModel.dynamo_items = nil
    @saved_table_name = CloudModel.table_name
    @saved_prefix = CloudModel.table_name_prefix
    @saved_suffix = CloudModel.table_name_suffix
    #CloudModel.table_name = "cloud_models"
    #CloudModel.table_name_prefix = nil
    #CloudModel.table_name_suffix = nil
  end

  after :each do
    CloudModel.table_name = @saved_table_name
    CloudModel.table_name_prefix = @saved_prefix
    CloudModel.table_name_suffix = @saved_suffix
  end


  it "should have a table_name derived from the class" do
    expect(CloudModel.table_name).to eq "cloud_models"
  end

  it "should handle a table_name derived from a namespaced class" do
    expect(CloudNamespace::CloudModel.table_name).to eq "cloud_namespace_cloud_models"
  end

  it "should have a table_name_prefix" do
    expect(CloudModel.table_name_prefix).to eq nil
    CloudModel.table_name_prefix = "foo_"
    expect(CloudModel.table_name_prefix).to eq "foo_"
  end

  it "should have a table_name_suffix" do
    expect(CloudModel.table_name_suffix).to eq Api.basename_suffix
  end

  it "should have a table_full_name method" do
    expect(CloudModel.table_full_name).to eq "cloud_models" + Api.basename_suffix
    CloudModel.table_name_prefix = "foo_"
    CloudModel.table_name_suffix = "_bar"
    expect(CloudModel.table_full_name).to eq "foo_cloud_models_bar"
  end

  it "should have a dynamo_table class_variable" do
    CloudModel.dynamo_table
    CloudModel.new.dynamo_table
    CloudModel.dynamo_table = true
    expect { CloudModel.new.dynamo_table = true }.to raise_error NoMethodError
    CloudModel.dynamo_table = nil
  end


  it "establish_db_connection should set dynamo_client, dynamo_table and dynamo_items" do
    expect_any_instance_of(AWS::DynamoDB::Table).to receive(:exists?).and_return(true)
    expect_any_instance_of(AWS::DynamoDB::Table).to receive(:status).and_return(:active)
    expect(CloudModel).not_to receive(:create_table)
    expect(CloudModel.dynamo_client).to eq nil
    expect(CloudModel.dynamo_table).to eq nil
    expect(CloudModel.dynamo_items).to eq nil
    CloudModel.establish_db_connection
    expect(CloudModel.dynamo_client).to be_an AWS::DynamoDB
    expect(CloudModel.dynamo_table).to be_an AWS::DynamoDB::Table
    expect(CloudModel.dynamo_items).to be_an AWS::DynamoDB::ItemCollection
  end

  it "establish_db_connection should return true if the table exists and is active" do
    expect_any_instance_of(AWS::DynamoDB::Table).to receive(:exists?).and_return(true)
    expect_any_instance_of(AWS::DynamoDB::Table).to receive(:status).and_return(:active)
    expect(CloudModel).not_to receive(:create_table)
    CloudModel.establish_db_connection
  end

  it "establish_db_connection should wait for the table to complete creation" do
    expect_any_instance_of(AWS::DynamoDB::Table).to receive(:exists?).and_return(true)
    expect_any_instance_of(AWS::DynamoDB::Table).to receive(:status).
      and_return(:creating, :creating, :creating, :creating, :active)
    expect(Object).to receive(:sleep).with(1).exactly(4).times
    expect(CloudModel).not_to receive(:create_table)
    CloudModel.establish_db_connection
  end

  it "establish_db_connection should wait for the table to delete before trying to create it again" do
    expect_any_instance_of(AWS::DynamoDB::Table).to receive(:exists?).and_return(true)
    expect_any_instance_of(AWS::DynamoDB::Table).to receive(:status).and_return(:deleting)
    expect_any_instance_of(AWS::DynamoDB::Table).to receive(:exists?).and_return(true, true, true, false)
    expect(Object).to receive(:sleep).with(1).exactly(3).times
    expect(CloudModel).to receive(:create_table).and_return(true)
    CloudModel.establish_db_connection
  end

  it "establish_db_connection should try to create the table if it doesn't exist" do
    expect_any_instance_of(AWS::DynamoDB::Table).to receive(:exists?).and_return(false)
    expect(CloudModel).to receive(:create_table).and_return(true)
    CloudModel.establish_db_connection
  end

  it "establish_db_connection should barf on an unknown table status" do
    expect_any_instance_of(AWS::DynamoDB::Table).to receive(:exists?).and_return(true)
    expect_any_instance_of(AWS::DynamoDB::Table).to receive(:status).twice.and_return(:syphilis)
    expect(CloudModel).not_to receive(:create_table)
    expect { CloudModel.establish_db_connection }. 
      to raise_error(OceanDynamo::UnknownTableStatus, "Unknown DynamoDB table status 'syphilis'")
  end

  it "create_table should try to create the table if it doesn't exist" do
    expect_any_instance_of(AWS::DynamoDB::Table).to receive(:exists?).and_return(false)
    t = double(AWS::DynamoDB::Table)
    allow(t).to receive(:status).and_return(:creating, :creating, :creating, :active)
    allow(t).to receive(:hash_key=).once
    allow(t).to receive(:range_key=).once
    expect_any_instance_of(AWS::DynamoDB::TableCollection).to receive(:create).
      with("cloud_models" + Api.basename_suffix, 
           10, 
           5, 
           hash_key: {uuid: :string}, 
           range_key: nil).
      and_return(t)
    expect(Object).to receive(:sleep).with(1).exactly(3).times
    CloudModel.establish_db_connection
  end


  it "delete_table should return true if the table was :active" do
    expect_any_instance_of(AWS::DynamoDB::Table).to receive(:exists?).twice.and_return(true)
    expect_any_instance_of(AWS::DynamoDB::Table).to receive(:status).twice.and_return(:active)
    expect(CloudModel).not_to receive(:create_table)
    expect_any_instance_of(AWS::DynamoDB::Table).to receive(:delete)
    CloudModel.establish_db_connection
    expect(CloudModel.delete_table).to eq true
  end

  it "delete_table should return false if the table wasn't :active" do
    expect_any_instance_of(AWS::DynamoDB::Table).to receive(:exists?).twice.and_return(true)
    expect_any_instance_of(AWS::DynamoDB::Table).to receive(:status).and_return(:active, :deleting)
    CloudModel.establish_db_connection
    expect(CloudModel.delete_table).to eq false
  end


  it "should keep the connection between two instantiations" do
    CloudModel.establish_db_connection
    i1 = CloudModel.new
    i1.save!
    i2 = CloudModel.new
    i2.save!
  end


  it "table_read_capacity_units should default to 10" do
    expect(CloudModel.table_read_capacity_units).to eq 10
  end

  it "table_write_capacity_units should default to 5" do
    expect(CloudModel.table_write_capacity_units).to eq 5
  end
  

  it "should have a table_connected variable" do
    expect(CloudModel).to respond_to :table_connected
  end

  it "should have a table_connect_policy variable" do
    expect(CloudModel).to respond_to :table_connect_policy
  end

  it "should have a table_create_policy variable" do
    expect(CloudModel).to respond_to :table_create_policy
  end

end
