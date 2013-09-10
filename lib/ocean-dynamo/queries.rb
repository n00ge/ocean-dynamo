module OceanDynamo
  class Base

    def self.find(hash, range=nil, consistent: false)
      item = dynamo_items[hash, range]
      raise RecordNotFound unless item.exists?
      new.send(:post_instantiate, item, consistent)
    end


    def self.count
      dynamo_table.item_count || -1    # The || -1 is for fake_dynamo specs.
    end

  end
end
