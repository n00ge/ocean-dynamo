require 'spec_helper'


describe CloudModel do

  before :all do
    CloudModel.establish_db_connection
  end


  describe "single string attributes" do
    describe "without defaults" do
      describe "before create" do

        it 'should default to the empty string' do
          CloudModel.new.token.should == ""
        end

        it "should be able to receive any init value" do
          CloudModel.new(token: nil).token.should == nil
          CloudModel.new(token: "Edwin").token.should == "Edwin"
          CloudModel.new(token: 3.14).token.should == 3.14
        end
      end

      describe "after instantiation" do

        it "should return a stored value" do
          i = CloudModel.create token: "hey"
          i.token.should == "hey"
          i.reload
          i.token.should == "hey"
          CloudModel.find(i.uuid, consistent: true).token.should == "hey"
        end

        it "should return a stored empty string" do
          i = CloudModel.create token: ""
          i.token.should == ""
          i.reload
          i.token.should == ""
          CloudModel.find(i.uuid, consistent: true).token.should == ""
        end
      end
    end

    describe "with defaults" do
      describe "before create" do

        it 'should be assigned the default' do
          CloudModel.new.credentials.should == "blah"
        end

        it "should be able to receive any init value" do
          CloudModel.new(credentials: nil).credentials.should == nil
          CloudModel.new(credentials: "Edwin").credentials.should == "Edwin"
          CloudModel.new(credentials: 3.14).credentials.should == 3.14
        end
      end

      describe "after instantiation" do

        it "should return a stored value" do
          i = CloudModel.create credentials: "hey"
          i.credentials.should == "hey"
          i.reload
          i.credentials.should == "hey"
          CloudModel.find(i.uuid, consistent: true).credentials.should == "hey"
        end

        it "should return a stored empty string" do
          i = CloudModel.create credentials: ""
          i.credentials.should == ""
          i.reload
          i.credentials.should == ""
          CloudModel.find(i.uuid, consistent: true).credentials.should == ""
        end

        it "should return a stored nil as the empty string" do
          i = CloudModel.create credentials: nil
          i.credentials.should == nil
          i.reload
          i.credentials.should == ""
          CloudModel.find(i.uuid, consistent: true).credentials.should == ""
        end
      end
    end
  end

  describe "string set attributes" do
    describe "without defaults" do
      describe "before create" do

        it 'should default to the empty string' do
          CloudModel.new.token.should == ""
        end

        it "should be able to receive any init value" do
          CloudModel.new(token: nil).token.should == nil
          CloudModel.new(token: "Edwin").token.should == "Edwin"
          CloudModel.new(token: 3.14).token.should == 3.14
        end
      end

      describe "after instantiation" do

        it "should return a stored set" do
          i = CloudModel.create token: "hey"
          i.token.should == "hey"
          i.reload
          i.token.should == "hey"
          CloudModel.find(i.uuid, consistent: true).token.should == "hey"
        end

        it "should return a stored empty set as the empty string" do
          i = CloudModel.create token: []
          i.token.should == []
          i.reload
          i.token.should == ""
          CloudModel.find(i.uuid, consistent: true).token.should == ""
        end
      end
    end

    describe "with defaults" do
      describe "before create" do

        it 'should be assigned the default' do
          CloudModel.new.credentials.should == "blah"
        end

        it "should be able to receive any init value" do
          CloudModel.new(credentials: nil).credentials.should == nil
          CloudModel.new(credentials: "Edwin").credentials.should == "Edwin"
          CloudModel.new(credentials: 3.14).credentials.should == 3.14
        end
      end

      describe "after instantiation" do

        it "should return a stored value" do
          i = CloudModel.create credentials: ["hey", "jude"]
          i.credentials.should == ["hey", "jude"]
          i.reload
          i.credentials.should == ["hey", "jude"]
          CloudModel.find(i.uuid, consistent: true).credentials.should == ["hey", "jude"]
        end

        it "should return a stored empty set" do
          i = CloudModel.create credentials: []
          i.credentials.should == []
          i.reload
          i.credentials.should == ""
          CloudModel.find(i.uuid, consistent: true).credentials.should == ""
        end

        it "should return a stored nil as the empty string" do
          i = CloudModel.create credentials: nil
          i.credentials.should == nil
          i.reload
          i.credentials.should == ""
          CloudModel.find(i.uuid, consistent: true).credentials.should == ""
        end
      end
    end

  end
end