require 'spec_helper'

class Target < OceanDynamo::Table
  dynamo_schema(table_name_suffix: Api.basename_suffix) do
  	attribute :name
  end
end

module OceanDynamo

  describe Relation do

    it "should take a class, store it in @klass and define a reader for it" do
      r = Relation.new Target
      expect(r.instance_variable_get(:@klass)).to eq Target
      expect(r.klass).to eq Target
    end

    it "should define #model as an alias for #klass" do
      expect(Relation.new(Target).model).to eq Target
    end

    # it "should take an optional hash, store it in @values and define a reader for them" do
    #   r = Relation.new Target, foo: :bar, baz: :quux
    #   r.instance_variable_get(:@values).should == {foo: :bar, baz: :quux}
    #   r.values.should == {foo: :bar, baz: :quux}
    # end

    # it "should return {} for values if not given at cons" do
    # 	Relation.new(Target).values.should == {}
    # end

    it "should when newly consed have a reader #loaded which returns false" do
      expect(Relation.new(Target).loaded).to eq false
      expect { Relation.new(Target).loaded = true }.to raise_error
    end

    it "should define #loaded? as an alias for #loaded" do
      expect(Relation.new(Target).loaded?).to eq false
    end

    it "new/build on an instance should cons a new instance of the klass" do
      expect(Relation.new(Target).new).to be_a Target
      expect(Relation.new(Target).build).to be_a Target
    end

    it "new/build should accept parameters" do
      t = Relation.new(Target).build name: "Peter"
      expect(t.name).to eq "Peter"
    end

    it "new/build should accept a block" do
      t = Relation.new(Target).build do |i|
      	i.name = "Blahonga"
      end
      expect(t.name).to eq "Blahonga"
    end
	
  end
end