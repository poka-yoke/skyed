require 'rspec/core/rake_task'
require 'rubocop/rake_task'

task default: [:spec, :plugin_specs, :rubocop]
task test: [:spec, :plugin_specs, :rubocop]

desc 'Run main specs'
RSpec::Core::RakeTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

desc 'Run plugin specs'
RSpec::Core::RakeTask.new(:plugin_specs) do |t|
  t.pattern = 'plugins/*/spec/**/*_spec.rb'
end

RuboCop::RakeTask.new
