module OceanDynamo
  class Table

    class_attribute :dynamo_resource, instance_writer: false
    self.dynamo_resource = nil

    class_attribute :dynamo_client, instance_writer: false
    self.dynamo_client = nil

    class_attribute :dynamo_table, instance_writer: false
    self.dynamo_table = nil

    class_attribute :table_name, instance_writer: false
    self.table_name = nil

    class_attribute :table_name_prefix, instance_writer: false
    self.table_name_prefix = nil

    class_attribute :table_name_suffix, instance_writer: false
    self.table_name_suffix = nil

    class_attribute :table_hash_key, instance_writer: false
    self.table_hash_key = nil

    class_attribute :table_range_key, instance_writer: false
    self.table_range_key = nil

    class_attribute :table_read_capacity_units, instance_writer: false
    self.table_read_capacity_units = 10

    class_attribute :table_write_capacity_units, instance_writer: false
    self.table_write_capacity_units = 5

    class_attribute :fields, instance_writer: false
    self.fields = nil

    class_attribute :table_connected, instance_writer: false
    self.table_connected = false

    class_attribute :table_connect_policy, instance_writer: false
    self.table_connect_policy = :late

    class_attribute :table_create_policy, instance_writer: false
    self.table_create_policy = false

    class_attribute :lock_attribute, instance_writer: false
    self.lock_attribute = :lock_version

    class_attribute :timestamp_attributes, instance_writer: false
    self.timestamp_attributes = [:created_at, :updated_at]

    class_attribute :relations, instance_writer: false
    self.relations = nil

    class_attribute :global_secondary_indexes, instance_writer: false
    self.global_secondary_indexes = nil

  end
end