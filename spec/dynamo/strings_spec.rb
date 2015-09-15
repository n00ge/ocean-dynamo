require 'spec_helper'


describe CloudModel do

  before :all do
    CloudModel.establish_db_connection
  end


  describe "single string attributes" do
    describe "without defaults" do
      describe "before create" do

        it 'should default to the empty string' do
          expect(CloudModel.new.token).to eq ""
        end

        it "should be able to receive any init value" do
          expect(CloudModel.new(token: nil).token).to eq nil
          expect(CloudModel.new(token: "Edwin").token).to eq "Edwin"
          expect(CloudModel.new(token: 3.14).token).to eq 3.14
        end
      end

      describe "after instantiation" do

        it "should return a stored value" do
          i = CloudModel.create token: "hey"
          expect(i.token).to eq "hey"
          i.reload
          expect(i.token).to eq "hey"
          expect(CloudModel.find(i.id, consistent: true).token).to eq "hey"
        end

        it "should return a stored empty string" do
          i = CloudModel.create token: ""
          expect(i.token).to eq ""
          i.reload
          expect(i.token).to eq ""
          expect(CloudModel.find(i.id, consistent: true).token).to eq ""
        end
      end
    end

    describe "with defaults" do
      describe "before create" do

        it 'should be assigned the default' do
          expect(CloudModel.new.credentials).to eq "blah"
        end

        it "should be able to receive any init value" do
          expect(CloudModel.new(credentials: nil).credentials).to eq nil
          expect(CloudModel.new(credentials: "Edwin").credentials).to eq "Edwin"
          expect(CloudModel.new(credentials: 3.14).credentials).to eq 3.14
        end
      end

      describe "after instantiation" do

        it "should return a stored value" do
          i = CloudModel.create credentials: "hey"
          expect(i.credentials).to eq "hey"
          i.reload
          expect(i.credentials).to eq "hey"
          expect(CloudModel.find(i.id, consistent: true).credentials).to eq "hey"
        end

        it "should return a stored empty string" do
          i = CloudModel.create credentials: ""
          expect(i.credentials).to eq ""
          i.reload
          expect(i.credentials).to eq ""
          expect(CloudModel.find(i.id, consistent: true).credentials).to eq ""
        end

        it "should return a stored nil as the empty string" do
          i = CloudModel.create credentials: nil
          expect(i.credentials).to eq nil
          i.reload
          expect(i.credentials).to eq ""
          expect(CloudModel.find(i.id, consistent: true).credentials).to eq ""
        end
      end
    end
  end

  describe "string set attributes" do
    describe "without defaults" do
      describe "before create" do

        it 'should default to the empty string' do
          expect(CloudModel.new.token).to eq ""
        end

        it "should be able to receive any init value" do
          expect(CloudModel.new(token: nil).token).to eq nil
          expect(CloudModel.new(token: "Edwin").token).to eq "Edwin"
          expect(CloudModel.new(token: 3.14).token).to eq 3.14
        end
      end

      describe "after instantiation" do

        it "should return a stored set" do
          i = CloudModel.create token: "hey"
          expect(i.token).to eq "hey"
          i.reload
          expect(i.token).to eq "hey"
          expect(CloudModel.find(i.id, consistent: true).token).to eq "hey"
        end

        it "should return a stored empty set as the empty string" do
          i = CloudModel.create token: []
          expect(i.token).to eq []
          i.reload
          expect(i.token).to eq ""
          expect(CloudModel.find(i.id, consistent: true).token).to eq ""
        end
      end
    end

    describe "with defaults" do
      describe "before create" do

        it 'should be assigned the default' do
          expect(CloudModel.new.credentials).to eq "blah"
        end

        it "should be able to receive any init value" do
          expect(CloudModel.new(credentials: nil).credentials).to eq nil
          expect(CloudModel.new(credentials: "Edwin").credentials).to eq "Edwin"
          expect(CloudModel.new(credentials: 3.14).credentials).to eq 3.14
        end
      end

      describe "after instantiation" do

        it "should return a stored value" do
          i = CloudModel.create credentials: ["hey", "jude"]
          expect(i.credentials).to eq ["hey", "jude"]
          i.reload
          expect(i.credentials).to eq ["hey", "jude"]
          expect(CloudModel.find(i.id, consistent: true).credentials).to eq ["hey", "jude"]
        end

        it "should return a stored empty set" do
          i = CloudModel.create credentials: []
          expect(i.credentials).to eq []
          i.reload
          expect(i.credentials).to eq ""
          expect(CloudModel.find(i.id, consistent: true).credentials).to eq ""
        end

        it "should return a stored nil as the empty string" do
          i = CloudModel.create credentials: nil
          expect(i.credentials).to eq nil
          i.reload
          expect(i.credentials).to eq ""
          expect(CloudModel.find(i.id, consistent: true).credentials).to eq ""
        end
      end
    end

  end
end