require 'coveralls'
Coveralls.wear!

task test: :spec

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task test: :features

require 'rubygems'
require 'cucumber'
require 'cucumber/rake/task'

Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = 'features --format pretty'
end

task test: :rubocop
SimpleCov.command_name 'Rubocop'
task :rubocop do
  sh 'rubocop'
end
