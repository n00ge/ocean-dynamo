module OceanDynamo
  module Queries

    # ---------------------------------------------------------
    #
    #  Class methods
    #
    # ---------------------------------------------------------

    def find(hash, range=nil, consistent: false)
      return hash.collect {|elem| find elem, range, consistent: consistent } if hash.is_a?(Array)
      _late_connect?
      hash = hash.id if hash.kind_of?(Table)    # TODO: We have (innocuous) leakage, fix!
      range = range.to_i if range.is_a?(Time)
      keys = { table_hash_key.to_s => hash }
      keys[table_range_key] = range if table_range_key && range
      options = { key: keys, consistent_read: consistent }
      item = dynamo_table.get_item(options).item
      unless item
        raise RecordNotFound, "can't find a #{self} with primary key ['#{hash}', #{range.inspect}]" 
      end
      new._setup_from_dynamo(item)
    end


    def find_by_key(*args)
      find(*args)
    rescue RecordNotFound
      nil
    end
    alias find_by_id find_by_key


    #
    # The number of records in the table. Updated every 6 hours or so;
    # thus isn't a reliable real-time measure of the number of table items.
    #
    def count(**options)
      _late_connect?
      dynamo_table.item_count
    end


    #
    # Returns all records in the table.
    # TODO: Rewrite to use smart scanner.
    #
    def all(consistent: false, **options)
      _late_connect?
      records = []
      options = { consistent_read: !!consistent }
      result = dynamo_table.scan(options)
      result.items.each do |hash|
        records << new._setup_from_dynamo(hash)
      end
      records
    end


    #
    # Looping through a collection of records from the database (using the +all+ method, 
    # for example) is very inefficient since it will try to instantiate all the objects at once.
    #
    # In that case, batch processing methods allow you to work with the records in batches, 
    # thereby greatly reducing memory consumption.
    #
    def find_each(limit: nil, batch_size: 1000, consistent: false)
      if consistent
        dynamo_items.each(limit: limit, batch_size: batch_size) do |item|
          yield new._setup_from_dynamo(item, consistent: consistent)  # Handle consistency above
        end
      else
        dynamo_items.select(limit: limit, batch_size: batch_size) do |item_data|
          yield new._setup_from_dynamo(item_data)
        end
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
    # def find_in_batches(start: nil, batch_size: 1000)
    #   []
    # end
  end
end
