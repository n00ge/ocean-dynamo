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
        { "token_global" => { 
            "keys" => ["token"], 
            "projection_type" => "ALL",
            "read_capacity_units" => 10,
            "write_capacity_units" => 5
            },
          "api_user_id_expires_at_global" => { 
            "keys" => ["api_user_id", "expires_at"], 
            "projection_type" => "KEYS_ONLY",
            "read_capacity_units" => 100,
            "write_capacity_units" => 5
            },
          "expires_at_global" => { 
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

    gsi = gsis.find { |i| i[:index_name] == "expires_at_global"}.to_hash
    expect(gsi[:key_schema]).to eq [{:attribute_name=>"expires_at", :key_type=>"HASH"}]
    expect(gsi[:projection]).to eq({:projection_type=>"KEYS_ONLY"})

    gsi = gsis.find { |i| i[:index_name] == "api_user_id_expires_at_global"}.to_hash
    expect(gsi[:key_schema]).to eq [{:attribute_name=>"api_user_id", :key_type=>"HASH"}, 
                                    {:attribute_name=>"expires_at", :key_type=>"RANGE"}]
    expect(gsi[:projection]).to eq({:projection_type=>"KEYS_ONLY"})

    gsi = gsis.find { |i| i[:index_name] == "token_global"}.to_hash
    expect(gsi[:key_schema]).to eq [{:attribute_name=>"token", :key_type=>"HASH"}]
    expect(gsi[:projection]).to eq({:projection_type=>"ALL"})
  end


  describe "condition_builder" do

    it "should accept a hash key and value" do
      c = Authentication.condition_builder(:token, "some-token-value")
      expect(c).to eq({
        expression_attribute_names: {"#H"=>:token}, 
        key_condition_expression: "#H = :hashval", 
        expression_attribute_values: {":hashval"=>"some-token-value"}})
    end

    it "should accept a hash key and value and a range key, comparator and value" do
      c = Authentication.condition_builder(:api_user_id, "some-api_user_id", 
                                           :expires_at, ">=", 0)
      expect(c).to eq({
        expression_attribute_names: {"#H"=>:api_user_id, "#R"=>:expires_at}, 
        key_condition_expression: "#H = :hashval AND #R >= :rangeval", 
        expression_attribute_values: {":hashval"=>"some-api_user_id", ":rangeval"=>0}})
    end

    it "should accept a :limit value" do
      c = Authentication.condition_builder(:api_user_id, "some-api_user_id", limit: 1)
      expect(c).to eq({
        expression_attribute_names: {"#H"=>:api_user_id}, 
        key_condition_expression: "#H = :hashval", 
        expression_attribute_values: {":hashval"=>"some-api_user_id"},
        limit: 1})
    end

    it "should accept a :consistent boolean (default false)" do
      c = Authentication.condition_builder(:api_user_id, "some-api_user_id", consistent: true)
      expect(c).to eq({
        expression_attribute_names: {"#H"=>:api_user_id}, 
        key_condition_expression: "#H = :hashval", 
        expression_attribute_values: {":hashval"=>"some-api_user_id"},
        consistent_read: true})
   end

    it "should accept a :scan_index_forward boolean (default true)" do
      c = Authentication.condition_builder(:api_user_id, "some-api_user_id", scan_index_forward: false)
      expect(c).to eq({
        expression_attribute_names: {"#H"=>:api_user_id}, 
        key_condition_expression: "#H = :hashval", 
        expression_attribute_values: {":hashval"=>"some-api_user_id"},
        scan_index_forward: false})
    end
  end


  describe "find_global_each" do

    it "should call in_batches with correct options" do
      expect(Authentication).to receive(:in_batches).
        with(:query, { expression_attribute_names: {"#H"=>:token}, 
                       key_condition_expression: "#H = :hashval", 
                       expression_attribute_values: {":hashval"=>"uyfuwef"}, 
                       index_name: "token_global"})
      Authentication.find_global_each :token, "uyfuwef"
    end
  end


  describe "find_global" do

    it "should call in_batches with correct options" do
      expect(Authentication).to receive(:in_batches).
        with(:query, { expression_attribute_names: {"#H"=>:token}, 
                       key_condition_expression: "#H = :hashval", 
                       expression_attribute_values: {":hashval"=>"uyfuwef"}, 
                       index_name: "token_global"})
      Authentication.find_global :token, "uyfuwef"
    end

    describe do

      before :all do
        Authentication.delete_all
        @a1 = Authentication.create! username: "joe", expires_at: 2.days.ago.utc,      token: 'x', max_age: 231, api_user_id: "j"
        @a2 = Authentication.create! username: "joe", expires_at: 1.days.ago.utc,      token: 'x', max_age: 332, api_user_id: "j"
        @a3 = Authentication.create! username: "sue", expires_at: 1.hour.ago.utc,      token: 'x', max_age: 555, api_user_id: "s"
        @a4 = Authentication.create! username: "sue", expires_at: 1.days.from_now.utc, token: 'y', max_age: 111, api_user_id: "s"
        @a5 = Authentication.create! username: "sue", expires_at: 2.days.from_now.utc, token: 'y', max_age: 222, api_user_id: "s"
      end

      it "should be able to find by token" do
        x = Authentication.find_global(:token, "x")
        expect(x.length).to eq 3
      end

      it "should be able to find by token and get all six attributes directly" do
        y = Authentication.find_global(:token, "y")
        expect(y.first.attributes.length).to eq 6
      end

      it "should be able to find by username and expires_at" do
        y = Authentication.find_global(:api_user_id, "s", :expires_at, ">=", Time.now.utc)
        expect(y.length).to eq 2
      end

      it "should be able to find by username and expires_at and get all six attributes indirectly" do
        y = Authentication.find_global(:api_user_id, "s", :expires_at, ">=", Time.now.utc)
        expect(y.length).to eq 2
        expect(y.first.attributes.length).to eq 6
      end

      it "should observe :limit" do
        x = Authentication.find_global(:token, "x", limit: 1)
        expect(x.length).to eq 1
      end

      it "should be able to find by username and expires_at and get results in order" do
        y = Authentication.find_global(:api_user_id, "s", :expires_at, ">=", Time.now.utc)
        expect(y.collect(&:max_age)).to eq [111, 222]
      end

      it "should be able to find by username and expires_at and get results in reverse order" do
        y = Authentication.find_global(:api_user_id, "s", :expires_at, ">=", Time.now.utc, 
                                       scan_index_forward: false)
        expect(y.collect(&:max_age)).to eq [222, 111]
      end

    end
  end

end
