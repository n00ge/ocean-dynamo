require 'spec_helper'


describe CloudModel do
  
  before :all do
    CloudModel.establish_db_connection
  end

  describe "single integer attributes" do
    describe "without defaults" do
      describe "before create" do

        it 'should default to nil' do
          expect(CloudModel.new.last_completed_step).to eq nil
        end

        it "should sanitise its init value" do
          expect(CloudModel.new(last_completed_step: nil).last_completed_step).to eq nil
          expect(CloudModel.new(last_completed_step: "Edwin").last_completed_step).to eq 0
          expect(CloudModel.new(last_completed_step: 3.14).last_completed_step).to eq 3
        end
      end

      describe "after instantiation" do

        it "should return a stored value" do
          i = CloudModel.create last_completed_step: 12345
          expect(i.last_completed_step).to eq 12345
          i.reload(consistent: true)
          expect(i.last_completed_step).to eq 12345
          expect(CloudModel.find(i.guid, consistent: true).last_completed_step).to eq 12345
        end

        it "should return a stored nil" do
          i = CloudModel.create last_completed_step: nil
          expect(i.last_completed_step).to eq nil
          i.reload(consistent: true)
          expect(i.last_completed_step).to eq nil
          expect(CloudModel.find(i.guid, consistent: true).last_completed_step).to eq nil
        end

        it "should convert values to integers" do
          i = CloudModel.create last_completed_step: "86400-extra"
          expect(i.last_completed_step).to eq  86400
          i.reload(consistent: true)
          expect(i.last_completed_step).to eq 86400
          expect(CloudModel.find(i.guid, consistent: true).last_completed_step).to eq 86400
        end

        it "should handle durations" do
          i = CloudModel.create last_completed_step: 1.day
          expect(i.last_completed_step).to eq  1.day
          i.reload(consistent: true)
          expect(i.last_completed_step).to eq 86400
          expect(CloudModel.find(i.guid, consistent: true).last_completed_step).to eq 86400
        end
      end
    end

    describe "with defaults" do
      describe "before create" do

        it 'should be assigned the default' do
          expect(CloudModel.new.int).to eq 1066
        end

        it "should sanitise its init value" do
          expect(CloudModel.new(int: nil).int).to eq nil
          expect(CloudModel.new(int: "Edwin").int).to eq 0
          expect(CloudModel.new(int: 3.14).int).to eq 3
        end
      end

      describe "after instantiation" do

        it "should return a stored value" do
          i = CloudModel.create int: 1066
          expect(i.int).to eq 1066
          i.reload(consistent: true)
          expect(i.int).to eq 1066
          expect(CloudModel.find(i.guid, consistent: true).int).to eq 1066
        end

        it "should return a stored nil" do
          i = CloudModel.create int: nil
          expect(i.int).to eq nil
          i.reload(consistent: true)
          expect(i.int).to eq nil
          expect(CloudModel.find(i.guid, consistent: true).int).to eq nil
        end

        it "should convert values to integers" do
          i = CloudModel.create int: "86400-extra"
          expect(i.int).to eq  86400
          i.reload(consistent: true)
          expect(i.int).to eq 86400
          expect(CloudModel.find(i.guid, consistent: true).int).to eq 86400
        end
      end
    end
  end

  describe "integer set attributes" do
    describe "without defaults" do
      describe "before create" do

        it 'should default to the empty string' do
          expect(CloudModel.new.last_completed_step).to eq nil
        end

        it "should sanitise its init value" do
          expect(CloudModel.new(last_completed_step: nil).last_completed_step).to eq nil
          expect(CloudModel.new(last_completed_step: "Edwin").last_completed_step).to eq 0
          expect(CloudModel.new(last_completed_step: 3.14).last_completed_step).to eq 3
        end
      end

      describe "after instantiation" do

        it "should return a stored set" do
          i = CloudModel.create last_completed_step: nil
          expect(i.last_completed_step).to eq nil
          i.reload(consistent: true)
          expect(i.last_completed_step).to eq nil
          expect(CloudModel.find(i.guid, consistent: true).last_completed_step).to eq nil
        end

        it "should return a stored empty set as the empty string" do
          i = CloudModel.create last_completed_step: []
          expect(i.last_completed_step).to eq []
          i.reload(consistent: true)
          expect(i.last_completed_step).to eq nil
          expect(CloudModel.find(i.guid, consistent: true).last_completed_step).to eq nil
        end
      end
    end

    describe "with defaults" do
      describe "before create" do

        it 'should be assigned the default' do
          expect(CloudModel.new.int).to eq 1066
        end

        it "should sanitise its init value" do
          expect(CloudModel.new(int: nil).int).to eq nil
          expect(CloudModel.new(int: "Edwin").int).to eq 0
          expect(CloudModel.new(int: 3.14).int).to eq 3
        end
      end

      describe "after instantiation" do

        it "should return a stored value" do
          i = CloudModel.create int: [55, -1, 2000]
          expect(i.int).to eq [55, -1, 2000]
          i.reload(consistent: true)
          expect(i.int.to_set).to eq [55, -1, 2000].to_set
          expect(CloudModel.find(i.guid, consistent: true).int.to_set).to eq [55, -1, 2000].to_set
        end

        it "should return a stored empty set" do
          i = CloudModel.create int: []
          expect(i.int).to eq []
          i.reload(consistent: true)
          expect(i.int).to eq nil
          expect(CloudModel.find(i.guid, consistent: true).int).to eq nil
        end

        it "should return a stored nil" do
          i = CloudModel.create int: nil
          expect(i.int).to eq nil
          i.reload(consistent: true)
          expect(i.int).to eq nil
          expect(CloudModel.find(i.guid, consistent: true).int).to eq nil
        end
      end
    end

  end
end