require 'bundler/gem_tasks'
require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs.push 'lib'
  t.libs.push 'spec'
  t.test_files = FileList.new('spec/**/*_spec.rb')
  t.verbose = true
end

require 'rubygems'
require 'cucumber'
require 'cucumber/rake/task'

Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = 'features --format pretty'
end

task test: :rubocop

task :rubocop do
  sh 'rubocop'
end
