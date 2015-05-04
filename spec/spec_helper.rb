require 'rspec'
require 'simplecov'
SimpleCov.start

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
