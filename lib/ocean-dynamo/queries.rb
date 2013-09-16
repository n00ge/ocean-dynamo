module OceanDynamo
  class Base

    def self.find(hash, range=nil, consistent: false)
      return hash.collect {|elem| find elem, range, consistent: consistent } if hash.is_a?(Array)
      _late_connect?
      item = dynamo_items[hash, range]
      unless item.exists?
        raise RecordNotFound, "can't find a #{self} with primary key ['#{hash}', #{range.inspect}]" 
      end
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


    #
    # Looping through a collection of records from the database (using the +all+ method, 
    # for example) is very inefficient since it will try to instantiate all the objects at once.
    #
    # In that case, batch processing methods allow you to work with the records in batches, 
    # thereby greatly reducing memory consumption.
    #
    def self.find_each(limit: nil, batch_size: 1000)
      dynamo_items.select(limit: limit, batch_size: 1000) do |item_data|
        yield new._setup_from_dynamo(item_data)
      end
      true
    end


    # #
    # # Yields each batch of records that was found by the find options as an array. The size of 
    # # each batch is set by the :batch_size option; the default is 1000.
    # #
    # # You can control the starting point for the batch processing by supplying the :start option. 
    # # This is especially useful if you want multiple workers dealing with the same processing queue. You can make worker 1 handle all the records between id 0 and 10,000 and worker 2 handle from 10,000 and beyond (by setting the :start option on that worker).
    # #
    # # It’s not possible to set the order.
    # #
    # def self.find_in_batches(start: nil, batch_size: 1000)
    #   []
    # end
  end
end
