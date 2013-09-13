module OceanDynamo

  class DynamoError < StandardError; end

  class TableNotFound < DynamoError; end

  class UnknownPrimaryKey < DynamoError; end

  class UnknownTableStatus < DynamoError; end

  class UnsupportedType < DynamoError; end

  class SerializationTypeMismatch < DynamoError; end

  class ConnectionNotEstablished < DynamoError; end

  class RecordNotFound < DynamoError; end

  class RecordNotSaved < DynamoError; end

  class RecordInvalid < DynamoError
    attr_reader :record # :nodoc:
    def initialize(record) # :nodoc:
      @record = record
      errors = @record.errors.full_messages.join(", ")
      super(I18n.t(:"#{@record.class.i18n_scope}.errors.messages.record_invalid", :errors => errors, :default => :"errors.messages.record_invalid"))
    end
  end

  class RecordNotDestroyed < DynamoError; end

  class StatementInvalid < DynamoError; end
    class RecordNotUnique < StatementInvalid; end   
    class InvalidForeignKey < StatementInvalid; end

  class StaleObjectError < DynamoError
    attr_reader :record # :nodoc:
    def initialize(record) # :nodoc:
      @record = record
      errors = @record.errors.full_messages.join(", ")
      super(I18n.t(:"#{@record.class.i18n_scope}.errors.messages.record_invalid", :errors => errors, :default => :"errors.messages.record_invalid"))
    end
  end
 
  class ReadOnlyRecord < DynamoError; end

  class DangerousAttributeError < DynamoError; end

  class UnknownAttributeError < NoMethodError; end

  class AttributeAssignmentError < DynamoError; end

  class MultiparameterAssignmentErrors < DynamoError; end

end
