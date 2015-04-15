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

task :build do
  require 'rubygems'
  require 'gems'
  puts 'Comparing versions'
  gemspec_re = /version\s+=\s+'([^']*)'$/
  current = File.open('skyed.gemspec').read.match(gemspec_re)[1]
  versions = Gems.versions('skyed').collect { |g| g['number'] }
  versions.each do |v|
    msg = "Gemspec version (#{current}) is the last version"
    msg += " (#{v}). Try release"
    fail msg if v == current
  end
  build
end

def build
  puts 'Building'
  `gem build skyed.gemspec`
end

def publish(version)
  require 'fileutils'
  require 'rubygems'
  require 'gems'
  puts 'Publishing'
  Gems.push File.new "skyed-#{version}.gem" unless ENV['FAKE']
  FileUtils.rm "skyed-#{version}.gem"
end

task :release do
  require 'git'
  changelog_re = /## (\d+\.\d+\.\d+) \((\d+-\d+-\d+)\)/
  changelog_matches = File.open('CHANGELOG.md', &:readline).match(changelog_re)
  new_version = changelog_matches[1]
  new_date = changelog_matches[2]
  gemspec_re = /version\s+=\s+'([^']*)'$/
  gemspec = File.open('skyed.gemspec').read
  current = gemspec.match(gemspec_re)[1]
  fail 'Update your CHANGELOG first, please' if current == new_version
  repo = Git.open('.')
  fail 'Switch to master and merge' unless repo.current_branch == 'master'
  version_re = /version(\s+)=(\s+)'#{current}'/
  new_gemspec = gemspec.gsub(version_re, "version\\1=\\2'#{new_version}'")
  date_re = /date(\s+)=(\s+)'.*'/
  new_gemspec = new_gemspec.gsub(date_re, "date\\1=\\2'#{new_date}'")
  puts 'Updating gemspec'
  File.open('skyed.gemspec', 'w') { |f| f.puts new_gemspec } unless ENV['FAKE']
  puts 'Tagging'
  repo.add_tag(
    "v#{new_version}",
    a: "v#{new_version}",
    m: "Releasing #{new_version}") unless ENV['FAKE']
  puts 'Pushing'
  repo.push(repo.remote('ifosch'), 'master', tags: true) unless ENV['FAKE']
  build
  publish(new_version)
end
