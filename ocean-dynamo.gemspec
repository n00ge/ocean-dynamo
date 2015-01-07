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
  s.summary     = "OceanDynamo is a massively scalable Amazon DynamoDB near drop-in replacement for 
ActiveRecord."
  s.description = 
"== OceanDynamo

OceanDynamo is a massively scalable Amazon DynamoDB near drop-in replacement for 
ActiveRecord.

As one important use case for OceanDynamo is to facilitate the conversion of SQL
databases to no-SQL DynamoDB databases, it is important that the syntax and semantics
of OceanDynamo are as close as possible to those of ActiveRecord. This includes
callbacks, exceptions and method chaining semantics. OceanDynamo follows this pattern 
closely and is of course based on ActiveModel.

The attribute and persistence layer of OceanDynamo is modeled on that of ActiveRecord:
there's +save+, +save!+, +create+, +update+, +update!+, +update_attributes+, +find_each+,
+destroy_all+, +delete_all+ and all the other methods you're used to. The design goal 
is always to implement as much of the ActiveRecord interface as possible, without 
compromising scalability. This makes the task of switching from SQL to no-SQL much easier.

Thanks to its structural similarity to ActiveRecord, OceanDynamo works with FactoryGirl.

OceanDynamo uses primary indices to retrieve related table items, meaning it scales without 
limits.

See also Ocean, a Rails framework for creating highly scalable SOAs in the cloud, in which
ocean-dynamo is used as a central component: http://wiki.oceanframework.net"

  s.required_ruby_version = '~> 2.1'
  s.license = 'MIT'

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  
  s.add_dependency "aws-sdk", '~> 1.0' 
  s.add_dependency "aws-sdk-core"
  s.add_dependency "activemodel"
  s.add_dependency "activesupport"

  #s.add_dependency "mini_portile", "0.6.0"  # Lose this ASAP
  #s.add_dependency "nokogiri", "1.6.3.1"    # Lose this ASAP

  s.add_development_dependency "rails", "~> 4.2.0"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "factory_girl_rails", "~> 4.0"
end
