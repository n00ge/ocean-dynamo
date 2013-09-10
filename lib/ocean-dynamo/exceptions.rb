module OceanDynamo

  class DynamoError < StandardError; end

  class UnknownPrimaryKey < DynamoError; end

  class UnknownTableStatus < DynamoError; end

  class UnsupportedType < DynamoError; end

  class SerializationTypeMismatch < DynamoError; end

  class ConnectionNotEstablished < DynamoError; end

  class RecordNotFound < DynamoError; end

  class RecordNotSaved < DynamoError; end

  class RecordInvalid < DynamoError; end     

  class RecordNotDestroyed < DynamoError; end

  class StatementInvalid < DynamoError; end
  
  class WrappedDatabaseException < StatementInvalid; end
    class RecordNotUnique < WrappedDatabaseException; end   
    class InvalidForeignKey < WrappedDatabaseException; end

  class StaleObjectError < DynamoError; end
 
  class ReadOnlyRecord < DynamoError; end

  class DangerousAttributeError < DynamoError; end

  class UnknownAttributeError < NoMethodError; end

  class AttributeAssignmentError < DynamoError; end

  class MultiparameterAssignmentErrors < DynamoError; end

end

