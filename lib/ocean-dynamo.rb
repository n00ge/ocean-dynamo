require "ocean-dynamo/engine"

require "aws-sdk"
require "active_model"
require "active_support"

require "ocean-dynamo/exceptions"
require "ocean-dynamo/class_variables"

require "ocean-dynamo/basal"
require "ocean-dynamo/tables"
require "ocean-dynamo/schema"
require "ocean-dynamo/attributes"
require "ocean-dynamo/persistence"
require "ocean-dynamo/queries"
require "ocean-dynamo/associations/associations"
require "ocean-dynamo/associations/belongs_to"
require "ocean-dynamo/associations/has_many"


module OceanDynamo
  class Table

    include ActiveModel::Model
    include ActiveModel::Validations::Callbacks

    define_model_callbacks :initialize, only: :after
    define_model_callbacks :save
    define_model_callbacks :create
    define_model_callbacks :update
    define_model_callbacks :destroy
    define_model_callbacks :commit, only: :after
    define_model_callbacks :touch


    include Basal

    include Tables
    extend Schema

    include Attributes
    include Persistence
    extend Queries

    include Associations
    include BelongsTo
    include HasMany


    def initialize(attrs={})
      run_callbacks :initialize do
        super
      end
    end

  end
end
