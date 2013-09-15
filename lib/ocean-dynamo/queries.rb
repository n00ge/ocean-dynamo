module OceanDynamo
  class Base

    def self.find(hash, range=nil, consistent: false)
      _late_connect?
      item = dynamo_items[hash, range]
      raise RecordNotFound, "can't find a #{self} with primary key ['#{hash}', #{range.inspect}]" unless item.exists?
      new._setup_from_dynamo(item, consistent: consistent)
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
    # The number of records in the table.
    #
    def self.count(**options)
      _late_connect?
      dynamo_items.count(options)
    end


    #
    # Returns all records in the table.
    #
    def self.all(**options)
      _late_connect?
      result = []
      dynamo_items.select(options) do |item_data| 
        result << new._setup_from_dynamo(item_data)
      end
      result
    end

  end
end
