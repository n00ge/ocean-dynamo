
f = File.join(Rails.root, "config/aws.yml")

unless File.exists?(f)
  puts
  puts "-----------------------------------------------------------------------"
  puts "AWS config file missing. Please copy config/aws.yml.example"
  puts "to config/aws.yml and tailor its contents to suit your dev setup."
  puts
  puts "NB: aws.yml is excluded from git version control as it will contain"
  puts "    data private to your Ocean system."
  puts "-----------------------------------------------------------------------"
  puts
  abort
end

require "aws-sdk"
AWS.config YAML.load(File.read(f))[Rails.env]

require "aws-sdk-core"
Aws.config = YAML.load(File.read(f))[Rails.env].except(:user_agent_prefix)
