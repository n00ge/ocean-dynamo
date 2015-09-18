require 'spec_helper'


class Authentication < OceanDynamo::Table
  dynamo_schema(:username, :expires_at,
                table_name_suffix: Api.basename_suffix, 
                create: true,
                timestamps: nil, locking: false) do

    attribute :token,       :string
    attribute :max_age,     :integer
    attribute :created_at,  :datetime
    attribute :expires_at,  :datetime
    attribute :api_user_id, :string

    global_secondary_index :token, projection: :all
    global_secondary_index :api_user_id, :expires_at, read_capacity_units: 100
    global_secondary_index :expires_at, write_capacity_units: 50
  end
end



describe Authentication do

  it "should have extra information in .fields" do
    expect(Authentication.fields).to eq({
      "username" =>    {"type"=>:string,   "default"=>""}, 
      "expires_at" =>  {"type"=>:datetime, "default"=>nil}, 
      "token" =>       {"type"=>:string,   "default"=>nil}, 
      "max_age" =>     {"type"=>:integer,  "default"=>nil}, 
      "created_at" =>  {"type"=>:datetime, "default"=>nil}, 
      "api_user_id" => {"type"=>:string,   "default"=>nil}})
  end

  it "should set .global_secondary_indexes for the class" do
    expect(Authentication.global_secondary_indexes).
      to eq(
        { "token" => { 
            "keys" => ["token"], 
            "projection_type" => "ALL",
            "read_capacity_units" => 10,
            "write_capacity_units" => 5
            },
          "api_user_id_expires_at" => { 
            "keys" => ["api_user_id", "expires_at"], 
            "projection_type" => "KEYS_ONLY",
            "read_capacity_units" => 100,
            "write_capacity_units" => 5
            },
          "expires_at" => { 
            "keys" => ["expires_at"], 
            "projection_type" => "KEYS_ONLY" ,
            "read_capacity_units" => 10,
            "write_capacity_units" => 50
          }
        }
      )
  end

  it "should return .table_attribute_definitions for all indexed attributes" do
    expect(Authentication.table_attribute_definitions).
      to eq [{:attribute_name=>"username",    :attribute_type=>"S"}, 
             {:attribute_name=>"expires_at",  :attribute_type=>"N"}, 
             {:attribute_name=>"token",       :attribute_type=>"S"}, 
             {:attribute_name=>"api_user_id", :attribute_type=>"S"}]
  end

  it "should create the table with the proper options" do
    Authentication.establish_db_connection
    gsis = Authentication.dynamo_table.global_secondary_indexes
    expect(gsis).to be_an Array
    expect(gsis.length).to eq 3
    gsi = gsis[0].to_hash
    expect(gsi[:index_name]).to eq "expires_at"
    expect(gsi[:key_schema]).to eq [{:attribute_name=>"expires_at", :key_type=>"HASH"}]
    expect(gsi[:projection]).to eq({:projection_type=>"KEYS_ONLY"})
    gsi = gsis[1].to_hash
    expect(gsi[:index_name]).to eq "api_user_id_expires_at"
    expect(gsi[:key_schema]).to eq [{:attribute_name=>"api_user_id", :key_type=>"HASH"}, 
                                    {:attribute_name=>"expires_at", :key_type=>"RANGE"}]
    expect(gsi[:projection]).to eq({:projection_type=>"KEYS_ONLY"})
    gsi = gsis[2].to_hash
    expect(gsi[:index_name]).to eq "token"
    expect(gsi[:key_schema]).to eq [{:attribute_name=>"token", :key_type=>"HASH"}]
    expect(gsi[:projection]).to eq({:projection_type=>"ALL"})
  end

end
