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


RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.infer_base_class_for_anonymous_controllers = false
  config.order = 'random'

  #config.include Rails.application.routes.url_helpers

  # Make "FactoryGirl" superfluous
  config.include FactoryGirl::Syntax::Methods

  # To clear the fake_dynamo DB before and/or after each run, uncomment as desired:
  config.before(:suite) { `curl -s -X DELETE http://localhost:4567` }
  # config.after(:suite)  { `curl -s -X DELETE http://localhost:4567` }
end


class Api
  #
  # Special version of Api.adorn_basename.
  #
  def self.adorn_basename(basename, chef_env: "dev", rails_env: "development",
                          suffix_only: false)
    fullname = suffix_only ? "_#{chef_env}" : "#{basename}_#{chef_env}"
    local_ip = UDPSocket.open {|s| s.connect("64.233.187.99", 1); s.addr.last}.gsub('.', '-')
    fullname += "_#{local_ip}_#{rails_env}"
    fullname
  end


  #
  # Special version of Api.basename_suffix.
  #
  def self.basename_suffix
    adorn_basename '', suffix_only: true, rails_env: Rails.env
  end

end
