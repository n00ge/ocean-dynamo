module OceanDynamo
  class Base

    def self.find(hash, range=nil, consistent: false)
      _late_connect?
      item = dynamo_items[hash, range]
      raise RecordNotFound, "can't find a #{self} with primary key ['#{hash}', #{range.inspect}]" unless item.exists?
      new.send(:dynamo_unpersist, item, consistent)
    end


    def self.find_by_key(*args)
      find(*args)
    rescue RecordNotFound
      nil
    end


    def self.find_by_id(*args)
      find_by_key(*args)
    end


    #
    # Does a scan of all items in the table and returns the count.
    #
    def self.count
      _late_connect?
      dynamo_items.count
    end

  end
end
