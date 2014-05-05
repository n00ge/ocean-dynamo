require 'spec_helper'


describe CloudModel do

  before :all do
    CloudModel.establish_db_connection
  end


  describe "single integer attributes" do
    describe "without defaults" do
      describe "before create" do

        it 'should default to nil' do
          CloudModel.new.last_completed_step.should == nil
        end

        it "should sanitise its init value" do
          CloudModel.new(last_completed_step: nil).last_completed_step.should == nil
          CloudModel.new(last_completed_step: "Edwin").last_completed_step.should == 0
          CloudModel.new(last_completed_step: 3.14).last_completed_step.should == 3
        end
      end

      describe "after instantiation" do

        it "should return a stored value" do
          i = CloudModel.create last_completed_step: 12345
          i.last_completed_step.should == 12345
          i.reload(consistent: true)
          i.last_completed_step.should == 12345
          CloudModel.find(i.uuid, consistent: true).last_completed_step.should == 12345
        end

        it "should return a stored nil" do
          i = CloudModel.create last_completed_step: nil
          i.last_completed_step.should == nil
          i.reload(consistent: true)
          i.last_completed_step.should == nil
          CloudModel.find(i.uuid, consistent: true).last_completed_step.should == nil
        end

        it "should convert values to integers" do
          i = CloudModel.create last_completed_step: "86400-extra"
          i.last_completed_step.should ==  86400
          i.reload(consistent: true)
          i.last_completed_step.should == 86400
          CloudModel.find(i.uuid, consistent: true).last_completed_step.should == 86400
        end

        it "should handle durations" do
          i = CloudModel.create last_completed_step: 1.day
          i.last_completed_step.should ==  1.day
          i.reload(consistent: true)
          i.last_completed_step.should == 86400
          CloudModel.find(i.uuid, consistent: true).last_completed_step.should == 86400
        end
      end
    end

    describe "with defaults" do
      describe "before create" do

        it 'should be assigned the default' do
          CloudModel.new.int.should == 1066
        end

        it "should sanitise its init value" do
          CloudModel.new(int: nil).int.should == nil
          CloudModel.new(int: "Edwin").int.should == 0
          CloudModel.new(int: 3.14).int.should == 3
        end
      end

      describe "after instantiation" do

        it "should return a stored value" do
          i = CloudModel.create int: 1066
          i.int.should == 1066
          i.reload(consistent: true)
          i.int.should == 1066
          CloudModel.find(i.uuid, consistent: true).int.should == 1066
        end

        it "should return a stored nil" do
          i = CloudModel.create int: nil
          i.int.should == nil
          i.reload(consistent: true)
          i.int.should == nil
          CloudModel.find(i.uuid, consistent: true).int.should == nil
        end

        it "should convert values to integers" do
          i = CloudModel.create int: "86400-extra"
          i.int.should ==  86400
          i.reload(consistent: true)
          i.int.should == 86400
          CloudModel.find(i.uuid, consistent: true).int.should == 86400
        end
      end
    end
  end

  describe "integer set attributes" do
    describe "without defaults" do
      describe "before create" do

        it 'should default to the empty string' do
          CloudModel.new.last_completed_step.should == nil
        end

        it "should sanitise its init value" do
          CloudModel.new(last_completed_step: nil).last_completed_step.should == nil
          CloudModel.new(last_completed_step: "Edwin").last_completed_step.should == 0
          CloudModel.new(last_completed_step: 3.14).last_completed_step.should == 3
        end
      end

      describe "after instantiation" do

        it "should return a stored set" do
          i = CloudModel.create last_completed_step: nil
          i.last_completed_step.should == nil
          i.reload(consistent: true)
          i.last_completed_step.should == nil
          CloudModel.find(i.uuid, consistent: true).last_completed_step.should == nil
        end

        it "should return a stored empty set as the empty string" do
          i = CloudModel.create last_completed_step: []
          i.last_completed_step.should == []
          i.reload(consistent: true)
          i.last_completed_step.should == nil
          CloudModel.find(i.uuid, consistent: true).last_completed_step.should == nil
        end
      end
    end

    describe "with defaults" do
      describe "before create" do

        it 'should be assigned the default' do
          CloudModel.new.int.should == 1066
        end

        it "should sanitise its init value" do
          CloudModel.new(int: nil).int.should == nil
          CloudModel.new(int: "Edwin").int.should == 0
          CloudModel.new(int: 3.14).int.should == 3
        end
      end

      describe "after instantiation" do

        it "should return a stored value" do
          i = CloudModel.create int: [55, -1, 2000]
          i.int.should == [55, -1, 2000]
          i.reload(consistent: true)
          i.int.to_set.should == [55, -1, 2000].to_set
          CloudModel.find(i.uuid, consistent: true).int.to_set.should == [55, -1, 2000].to_set
        end

        it "should return a stored empty set" do
          i = CloudModel.create int: []
          i.int.should == []
          i.reload(consistent: true)
          i.int.should == nil
          CloudModel.find(i.uuid, consistent: true).int.should == nil
        end

        it "should return a stored nil" do
          i = CloudModel.create int: nil
          i.int.should == nil
          i.reload(consistent: true)
          i.int.should == nil
          CloudModel.find(i.uuid, consistent: true).int.should == nil
        end
      end
    end

  end
end