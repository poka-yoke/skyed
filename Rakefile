require 'coveralls'
Coveralls.wear!

task test: :spec

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task test: :rubocop
SimpleCov.command_name 'Rubocop'
task :rubocop do
  sh 'rubocop'
end
