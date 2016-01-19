require 'rspec'
require 'simplecov'
SimpleCov.start

Instance = Struct.new(
  :instance_id,
  :hostname,
  :stack_id,
  :layer_ids,
  :status,
  :ec2_instance_id,
  :public_dns
)
Layer = Struct.new(:stack_id, :layer_id, :name)
Stack = Struct.new(:stack_id, :name)
AccessKey = Struct.new(:access_key_id)
HealthCheck = Struct.new(
  :target,
  :interval,
  :timeout,
  :unhealthy_threshold,
  :healthy_threshold
)

RSpec.configure do |config|
  original_stderr = $stderr
  original_stdout = $stdout
  config.before(:all) do
    $stderr = StringIO.new
    $stdout = StringIO.new
  end
  config.after(:all) do
    $stderr = original_stderr
    $stdout = original_stdout
  end
end unless ENV['TEST_OUTPUT']
