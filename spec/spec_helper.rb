require 'simplecov'
SimpleCov.start do
  add_filter "/vendor/"
  add_filter "spec/dummy/config/initializers/aws.rb"
end

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require 'rspec/rails'
require 'factory_girl_rails'

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# DynamoDB table cleaner
CHEF_ENV = "master" unless defined?(CHEF_ENV)
regexp = Regexp.new("^.+_#{CHEF_ENV}_[0-9]{1,3}-[0-9]{1,3}-[0-9]{1,3}-[0-9]{1,3}_test$")
cleaner = lambda { 
  c = Aws::DynamoDB::Client.new
  c.list_tables.table_names.each do |t| 
    begin
      c.delete_table({table_name: t}) if t =~ regexp
    rescue Aws::DynamoDB::Errors::LimitExceededException
      sleep 1
      retry
    end
  end
}

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.infer_base_class_for_anonymous_controllers = false
  config.order = 'random'

  #config.include Rails.application.routes.url_helpers

  # Make "FactoryGirl" superfluous
  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) { cleaner.call }
  config.after(:suite) { cleaner.call }
end

