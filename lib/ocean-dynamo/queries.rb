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
    #
    def all(consistent: false, **options)
      _late_connect?
      records = []
      in_batches :scan, { consistent_read: !!consistent } do |attrs|
        records << new._setup_from_dynamo(attrs)
      end
      records
    end


    #
    # This method takes a block and yields it to every record in a table.
    # +message+ must be either :scan or :query.
    # +options+ is the hash of options to pass to the scan or query operation.
    #
    # TODO: Add support for
    #   index_name: "IndexName",
    #   select: "ALL_ATTRIBUTES", # ALL_ATTRIBUTES, ALL_PROJECTED_ATTRIBUTES, SPECIFIC_ATTRIBUTES, COUNT
    #
    def in_batches(message, options, &block)
      _late_connect?
      loop do
        result = dynamo_table.send message, options
        result.items.each do |hash|
          yield hash
        end
        return true unless result.last_evaluated_key
        options[:exclusive_start_key] = result.last_evaluated_key
      end
    end


    #
    # Looping through a collection of records from the database (using the +all+ method, 
    # for example) is very inefficient since it will try to instantiate all the objects at 
    # once. Batch processing methods allow you to work with the records in batches, 
    # thereby greatly reducing memory consumption.
    #
    # TODO: Add support for
    #   index_name: "IndexName",
    #   select: "ALL_ATTRIBUTES", # ALL_ATTRIBUTES, ALL_PROJECTED_ATTRIBUTES, SPECIFIC_ATTRIBUTES, COUNT
    #
    def find_each(consistent: false, limit: nil, batch_size: nil)
      options = { consistent_read: consistent }
      batch_size = limit if limit && batch_size && limit < batch_size
      options[:limit] = batch_size if batch_size   
      in_batches :scan, options do |attrs|
        if limit
          return true if limit <= 0
          limit = limit - 1
        end
        yield new._setup_from_dynamo(attrs)
      end
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


    def condition_builder(hash_key, hash_value,
                          range_key=nil, comparator=nil, range_value=nil,
                          limit: nil, consistent: false, scan_index_forward: true)
      if range_key
        options = { 
          expression_attribute_names: { "#H" => hash_key, "#R" => range_key },
          key_condition_expression: "#H = :hashval AND #R #{comparator} :rangeval",
          expression_attribute_values: { ":hashval" => hash_value, ":rangeval" => range_value }
        }
      else
        options = { 
          expression_attribute_names: { "#H" => hash_key },
          key_condition_expression: "#H = :hashval",
          expression_attribute_values: { ":hashval" => hash_value }
        }
      end
      options[:limit] = limit if limit
      options[:consistent_read] = consistent if consistent
      options[:scan_index_forward] = scan_index_forward if !scan_index_forward
      options
    end


    #
    # This method finds each item of a global secondary index, sequentially yielding each item
    # to the given block (required). The parameters are as follows:
    #
    # +hash_key+    The name of the hash key to use (required).
    # +hash_value+  The value of the hash key to match (required).
    # +range_key+   The name of the range key to use (optional).
    # +comparator+  The comparator to use. "=", "<", ">", "<=", ">=". (optional).
    # +range-value+ The value of the range key to match (optional).
    # 
    # Note that +range_key+ is optional, but if it's present, then the +comparator+ and
    # the +range_value+ must also be given. They must either all be present or absent.
    #
    # The following keyword arguments are accepted:
    # 
    # +:limit+              The maximum number of items to read.
    # +:scan_index_forward+ If false, items will be in reverse order.
    #
    # If the index contains all attributes, no extra read will be performed. If it doesn't,
    # the entire item will be fetched using an extra read operation.
    #
    def find_global_each(hash_key, hash_value,
                         range_key=nil, comparator=nil, range_value=nil,
                         limit: nil, scan_index_forward: true,
                         &block)
      hash_value = hash_value.to_i if hash_value.is_a?(Time)
      range_value = range_value.to_i if range_value.is_a?(Time)
      options = condition_builder(hash_key, hash_value, range_key, comparator, range_value,
                                  limit: limit, scan_index_forward: scan_index_forward)
      index_name = (range_key ? "#{hash_key}_#{range_key}" : hash_key.to_s) + "_global"
      options[:index_name] = index_name
      raise "Undefined global index: #{index_name}" unless global_secondary_indexes[index_name]
      all_projected = global_secondary_indexes[index_name]["projection_type"] == "ALL"
      in_batches :query, options do |attrs|
        if limit
          return if limit <= 0
          limit = limit - 1
        end
        if all_projected
          yield new._setup_from_dynamo(attrs)
        else
          yield find(attrs[table_hash_key.to_s], table_range_key && attrs[table_range_key.to_s])
        end
      end
    end


    #
    # This method takes the same args as +find_global_each+ but returns all found items as
    # an array.
    #
    def find_global(*args)
      result = []
      find_global_each(*args) do |item|
        result << item
      end
      result
    end

  end
end
