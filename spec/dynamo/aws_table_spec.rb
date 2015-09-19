require 'spec_helper'


describe CloudModel do
  
  before :all do
    CloudModel.establish_db_connection
  end

  before :each do
    CloudModel.dynamo_resource = nil
    CloudModel.dynamo_client = nil
    CloudModel.dynamo_table = nil
    @saved_table_name = CloudModel.table_name
    @saved_prefix = CloudModel.table_name_prefix
    @saved_suffix = CloudModel.table_name_suffix
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


  it "establish_db_connection should set dynamo_resource, dynamo_client, and dynamo_table" do
    expect(CloudModel).to receive(:table_exists?).and_return(true)
    expect(CloudModel).to receive(:fresh_table_status).and_return("ACTIVE")
    expect(CloudModel).not_to receive(:create_table)
    expect(CloudModel.dynamo_resource).to eq nil
    expect(CloudModel.dynamo_client).to eq nil
    expect(CloudModel.dynamo_table).to eq nil
    CloudModel.establish_db_connection
    expect(CloudModel.dynamo_resource).to be_an Aws::DynamoDB::Resource
    expect(CloudModel.dynamo_client).to be_an Aws::DynamoDB::Client
    expect(CloudModel.dynamo_table).to be_an Aws::DynamoDB::Table
  end

  it "establish_db_connection should return true if the table exists and is active" do
    expect(CloudModel).to receive(:table_exists?).and_return(true)
    expect(CloudModel).to receive(:fresh_table_status).and_return("ACTIVE")
    expect(CloudModel).not_to receive(:create_table)
    CloudModel.establish_db_connection
  end

  it "establish_db_connection should wait for the table to complete creation" do
    expect(CloudModel).to receive(:table_exists?).and_return(true)
    expect(CloudModel).to receive(:fresh_table_status).
      and_return("CREATING", "CREATING", "CREATING", "CREATING", "ACTIVE")
    expect_any_instance_of(Object).to receive(:sleep).with(1).exactly(4).times
    expect(CloudModel).not_to receive(:create_table)
    CloudModel.establish_db_connection
  end

  it "establish_db_connection should wait for the table to delete before trying to create it again" do
    expect(CloudModel).to receive(:table_exists?).and_return(true, true, true, false)
    expect(CloudModel).to receive(:fresh_table_status).exactly(3).times.and_return("DELETING")
    expect_any_instance_of(Object).to receive(:sleep).with(1).exactly(4).times  
    expect(CloudModel).to receive(:create_table).and_return(true)  
    CloudModel.establish_db_connection
  end

  it "establish_db_connection should try to create the table if it doesn't exist" do
    expect(CloudModel).to receive(:table_exists?).and_return(false)
    expect(CloudModel).to receive(:create_table)
    CloudModel.establish_db_connection
  end

  it "establish_db_connection should barf on an unknown table status" do
    expect(CloudModel).to receive(:table_exists?).and_return(true)
    expect(CloudModel).to receive(:fresh_table_status).and_return("SYPHILIS")
    expect(CloudModel).not_to receive(:create_table)
    expect { CloudModel.establish_db_connection }. 
      to raise_error(OceanDynamo::UnknownTableStatus, "Unknown DynamoDB table status 'SYPHILIS'")
  end

  it "create_table should sleep until the table becomes active after creating it" do
    expect(CloudModel).to receive(:table_exists?).and_return(false)
    expect_any_instance_of(Aws::DynamoDB::Resource).to receive(:create_table)
    expect(CloudModel).to receive(:fresh_table_status).and_return("CREATING", "CREATING", "CREATING", "ACTIVE")
    expect_any_instance_of(Object).to receive(:sleep).with(1).exactly(3).times
    CloudModel.establish_db_connection
  end


  it "delete_table should return true if the table was :active" do
    expect(CloudModel).to receive(:table_exists?).and_return(true)
    expect(CloudModel).to receive(:fresh_table_status).twice.and_return("ACTIVE")
    expect(CloudModel).not_to receive(:create_table)
    expect_any_instance_of(Aws::DynamoDB::Table).to receive(:delete)
    CloudModel.establish_db_connection
    expect(CloudModel.delete_table).to eq true
  end

  it "delete_table should return false if the table wasn't ACTIVE" do
    expect(CloudModel).to receive(:table_exists?).and_return(true)
    expect(CloudModel).to receive(:fresh_table_status).and_return("ACTIVE", "DELETING")
    CloudModel.establish_db_connection
    expect(CloudModel.delete_table).to eq false
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
