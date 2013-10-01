require 'spec_helper'

class Target < OceanDynamo::Table
  dynamo_schema() do
  	attribute :name
  end
end

module OceanDynamo

  describe Relation do

    it "should take a class, store it in @klass and define a reader for it" do
      r = Relation.new Target
      r.instance_variable_get(:@klass).should == Target
      r.klass.should == Target
    end

    it "should define #model as an alias for #klass" do
      Relation.new(Target).model.should == Target
    end

    it "should take an optional hash, store it in @values and define a reader for them" do
      r = Relation.new Target, foo: :bar, baz: :quux
      r.instance_variable_get(:@values).should == {foo: :bar, baz: :quux}
      r.values.should == {foo: :bar, baz: :quux}
    end

    it "should return {} for values if not given at cons" do
    	Relation.new(Target).values.should == {}
    end

    it "should when newly consed have a reader #loaded which returns false" do
      Relation.new(Target).loaded.should == false
      expect { Relation.new(Target).loaded = true }.to raise_error
    end

    it "should define #loaded? as an alias for #loaded" do
      Relation.new(Target).loaded?.should == false
    end

    it "new/build on an instance should cons a new instance of the klass" do
      Relation.new(Target).new.should be_a Target
      Relation.new(Target).build.should be_a Target
    end

    it "new/build should accept parameters" do
      t = Relation.new(Target).build name: "Peter"
      t.name.should == "Peter"
    end

    it "new/build should accept a block" do
      t = Relation.new(Target).build do |i|
      	i.name = "Blahonga"
      end
      t.name.should == "Blahonga"
    end
	
  end
end