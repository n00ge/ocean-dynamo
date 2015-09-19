require 'spec_helper'


class Auth1 < OceanDynamo::Table
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



describe Auth1 do

  it "should have extra information in .fields" do
    expect(Auth1.fields).to eq({
      "username" =>    {"type"=>:string,   "default"=>""}, 
      "expires_at" =>  {"type"=>:datetime, "default"=>nil}, 
      "token" =>       {"type"=>:string,   "default"=>nil, "local_secondary_index"=>true}, 
      "max_age" =>     {"type"=>:integer,  "default"=>nil}, 
      "created_at" =>  {"type"=>:datetime, "default"=>nil}, 
      "api_user_id" => {"type"=>:string,   "default"=>nil}})
  end

  it "should set .local_secondary_indexes for the class" do
    expect(Auth1.local_secondary_indexes).to eq(["token"])
  end

  it "should return .table_attribute_definitions for all indices" do
    expect(Auth1.table_attribute_definitions).
      to eq [{:attribute_name=>"username",   :attribute_type=>"S"}, 
             {:attribute_name=>"expires_at", :attribute_type=>"N"}, 
             {:attribute_name=>"token",      :attribute_type=>"S"}]
  end

  it "should create the table with the proper options" do
    Auth1.establish_db_connection
    lsis = Auth1.dynamo_table.local_secondary_indexes
    expect(lsis).to be_an Array
    expect(lsis.length).to eq 1
    lsi = lsis.first.to_hash
    expect(lsi[:index_name]).to eq "token"
    expect(lsi[:key_schema]).to eq [{:attribute_name=>"username", :key_type=>"HASH"}, 
                                    {:attribute_name=>"token", :key_type=>"RANGE"}]
    expect(lsi[:projection]).to eq({:projection_type=>"KEYS_ONLY"})
  end


  describe "find_local_each" do

    it "should call in_batches with correct options" do
      expect(Auth1).to receive(:in_batches).
        with(:query, { expression_attribute_names: {"#H"=>:username, "#R"=>:token}, 
                       key_condition_expression: "#H = :hashval AND #R >= :rangeval", 
                       expression_attribute_values: {":hashval"=>"albert", ":rangeval"=>"0"}, 
                       index_name: "token",
                       consistent_read: true,
                       select: "ALL_ATTRIBUTES"})
      Auth1.find_local_each :username, "albert", :token, ">=", "0", consistent: true
    end

    it "should barf on an undeclared local index" do
      expect{ Auth1.find_local_each :username, "albert", :xxxxxxx, ">=", "0", consistent: true }.
        to raise_error(RuntimeError, "Undefined local index: xxxxxxx")
    end

    it "should barf on a non-primary hash key" do
      expect{ Auth1.find_local_each :max_age, "albert", :token, ">=", "0", consistent: true }.
        to raise_error(RuntimeError, "The hash_key is :max_age but must be :username")
    end
  end


  describe "find_local" do

    it "should call in_batches with correct options" do
      expect(Auth1).to receive(:in_batches).
        with(:query, { expression_attribute_names: {"#H"=>:username, "#R"=>:token}, 
                       key_condition_expression: "#H = :hashval AND #R >= :rangeval", 
                       expression_attribute_values: {":hashval"=>"albert", ":rangeval"=>"0"}, 
                       index_name: "token",
                       consistent_read: true,
                       select: "ALL_ATTRIBUTES"})
      Auth1.find_local :username, "albert", :token, ">=", "0", consistent: true
    end

    describe do

      before :all do
        Auth1.delete_all
        @a1 = Auth1.create! username: "joe", expires_at: 2.days.ago.utc,      token: 'x', max_age: 231
        @a2 = Auth1.create! username: "joe", expires_at: 1.days.ago.utc,      token: 'x', max_age: 332
        @a3 = Auth1.create! username: "sue", expires_at: 1.hour.ago.utc,      token: 'x', max_age: 555
        @a4 = Auth1.create! username: "sue", expires_at: 1.days.from_now.utc, token: 'y', max_age: 111
        @a5 = Auth1.create! username: "sue", expires_at: 2.days.from_now.utc, token: 'y', max_age: 222
      end

      it "should be able to find by token" do
        x = Auth1.find_local(:username, "joe", :token, "=", "x")
        expect(x.length).to eq 2
        y = Auth1.find_local(:username, "sue", :token, ">=", "x")
        expect(y.length).to eq 3
      end

      it "should be able to find by token and get all six attributes directly" do
        y = Auth1.find_local(:username, "sue", :token, "=", "x")
        expect(y.first.attributes.length).to eq 6
      end

      it "should observe :limit" do
        x = Auth1.find_local(:username, "sue", :token, "=", "y", limit: 1)
        expect(x.length).to eq 1
      end

      it "should be able to find by username and token and get results in order" do
        x = Auth1.find_local(:username, "sue", :token, "=", "y")
        expect(x.length).to eq 2
        expect(x.collect(&:max_age).to_set).to eq [111, 222].to_set  # Items can be in any order
      end

      it "should be able to find by username and token and get results in reverse order" do
        y = Auth1.find_local(:username, "sue", :token, ">=", "x", 
                                       scan_index_forward: false)
        expect(y.collect(&:token)).to eq ["y", "y", "x"]
      end

    end
  end

end

