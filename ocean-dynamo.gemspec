$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "ocean-dynamo/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ocean-dynamo"
  s.version     = OceanDynamo::VERSION
  s.authors     = ["Peter Bengtson"]
  s.email       = ["peter@peterbengtson.com"]
  s.homepage    = "https://github.com/OceanDev/ocean-dynamo"
  s.summary     = "This gem implements an ActiveRecord-like DynamoDB ORM class."
  s.description = 
"== OceanDynamo

This is the OceanDynamo ruby gem, implementing a highly scalable Amazon DynamoDB near drop-in 
replacement for ActiveRecord.

As one important use case for OceanDynamo is to facilitate the conversion of SQL based
ActiveRecord models to DynamoDB based models, it is important that the syntax and semantics
of OceanDynamo's operations are as close as possible to those of ActiveRecord, including
callbacks, exceptions and support methods. Ocean-dynamo follows this pattern closely and
is of course based on ActiveModel.

The attribute and persistence layer of OceanDynamo is modeled on that of ActiveRecord:
there's +save+, +save!+, +create+, +update+, +update!+, +update_attributes+ and all the other
methods you're used to. The design goal is always to implement as much as possible of the
ActiveRecord interface, without sacrificing scalability. This makes the task of switching from
SQL to no-SQL much easier.

OceanDynamo will use secondary indices to retrieve related table items, 
which means OceanDynamo tables will scale without limits.

Thanks to its structural similarity to ActiveRecord, OceanDynamo works with FactoryGirl.
To facilitate testing, future versions will keep track of and delete instances after tests.

See also Ocean, a Rails framework for creating highly scalable SOAs in the cloud, in which
ocean-dynamo is used as a central component: http://wiki.oceanframework.net"
  s.required_ruby_version = '>= 2.0.0'
  s.license = 'MIT'

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  
  s.add_dependency "aws-sdk", '~> 1.0'  # Amazon Web Services Ruby SDK

  s.add_development_dependency "rails", "~> 4.0"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "factory_girl_rails", "~> 4.0"
  s.add_development_dependency "fake_dynamo", "~> 0.1.3"
end
