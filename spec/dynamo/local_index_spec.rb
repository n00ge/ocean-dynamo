require 'spec_helper'


class Authentication < OceanDynamo::Table
  dynamo_schema(:username, :expires_at,
                table_name_suffix: Api.basename_suffix, 
                create: true,
                timestamps: nil, locking: false) do
    attribute :token,       :string,   local_secondary_index: true
    attribute :max_age,     :integer
    attribute :created_at,  :datetime
    attribute :expires_at,  :datetime
    attribute :api_user_id, :string
  end
end



describe Authentication do

  it "should have extra information in fields" do
    expect(Authentication.fields).to eq({
      "username" =>    {"type"=>:string,   "default"=>""}, 
      "expires_at" =>  {"type"=>:datetime, "default"=>nil}, 
      "token" =>       {"type"=>:string,   "default"=>nil, "local_secondary_index"=>true}, 
      "max_age" =>     {"type"=>:integer,  "default"=>nil}, 
      "created_at" =>  {"type"=>:datetime, "default"=>nil}, 
      "api_user_id" => {"type"=>:string,   "default"=>nil}})
  end

  it "should set local_secondary_indexes for the class" do
    expect(Authentication.local_secondary_indexes).to eq(["token"])
  end

  it "should return table_attribute_definitions for all indices" do
    expect(Authentication.table_attribute_definitions).
      to eq [{:attribute_name=>"username",   :attribute_type=>"S"}, 
             {:attribute_name=>"expires_at", :attribute_type=>"N"}, 
             {:attribute_name=>"token",      :attribute_type=>"S"}]
  end

  it "should call create_table with the proper options" do
    Authentication.establish_db_connection
    lsis = Authentication.dynamo_table.local_secondary_indexes
    expect(lsis).to be_an Array
    expect(lsis.length).to eq 1
    lsi = lsis.first.to_hash
    expect(lsi[:index_name]).to eq "token"
    expect(lsi[:key_schema]).to eq [{:attribute_name=>"username", :key_type=>"HASH"}, 
                                    {:attribute_name=>"token", :key_type=>"RANGE"}]
    expect(lsi[:projection]).to eq({:projection_type=>"KEYS_ONLY"})
  end

end




