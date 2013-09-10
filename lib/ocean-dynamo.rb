require "ocean-dynamo/engine"

require "aws-sdk"

require "ocean-dynamo/base"
require "ocean-dynamo/exceptions"
require "ocean-dynamo/class_variables"
require "ocean-dynamo/tables"
require "ocean-dynamo/schema"
require "ocean-dynamo/callbacks"
require "ocean-dynamo/attributes"
require "ocean-dynamo/queries"
require "ocean-dynamo/persistence"


module OceanDynamo

  DEFAULT_ATTRIBUTES = [
    [:created_at,   :datetime], 
    [:updated_at,   :datetime],
    [:lock_version, :integer, default: 0]
  ]

end
