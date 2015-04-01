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

task :'clean-tmp' do
  require 'fileutils'
  paths = %w(/tmp/.skyed /tmp/.ansible /tmp/.vagrant.d /tmp/Library)
  paths += %w( /tmp/Virtualbox\ VMs /tmp/opsworks /tmp/.vbox-ifosch-ipc)
  paths.each do |path|
    puts "Removing #{path}..."
    FileUtils.rm_rf(path)
  end
end

task :'build-tmp' do
  require 'git'
  current_repo = Git.open(Dir.pwd)
  current_remote = current_repo.remote('origin').url
  current_remote ||= current_repo.remotes.first.url
  user = current_remote.split(':')[1].split('/')[-2]
  remote = ENV['OW_REMOTE'] || current_remote.sub('skyed', 'opsworks')
  puts "Cloning #{remote} into /tmp/opsworks"
  Git.clone(remote, '/tmp/opsworks') unless File.directory?('/tmp/opsworks')
  user_remote = remote.split(':')[0] + ':' + user + '/' + remote.split('/')[-1]
  repo = Git.open('/tmp/opsworks')
  puts "Adding remote #{user} with url: #{user_remote}"
  repo.add_remote(user, user_remote) unless repo.remote(user).url
end
