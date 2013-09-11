module OceanDynamo
  class Base

    def self.find(hash, range=nil, consistent: false)
      _connect_late?
      item = dynamo_items[hash, range]
      raise RecordNotFound unless item.exists?
      new.send(:dynamo_unpersist, item, consistent)
    end


    def self.find_by_key(*args)
      find(*args)
    rescue RecordNotFound
      nil
    end


    def self.count
      _connect_late?
      dynamo_table.item_count || -1    # The || -1 is for fake_dynamo specs.
    end

  end
end
