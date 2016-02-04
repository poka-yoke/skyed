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
  FileUtils.rm "skyed-#{version}.gem" unless ENV['FAKE']
end

task :release do
  require 'git'
  changelog_re = /## (\d+\.\d+\.\d+(|\..*)) \(\?\?\?\?-\?\?-\?\?\)/
  changelog = File.open('CHANGELOG.md').read
  changelog_matches = changelog.match(changelog_re)
  fail 'Update your CHANGELOG first, please' if changelog_matches.nil?
  new_version = changelog_matches[1]
  skyed_branch = 'master'
  skyed_branch = 'v0.2' if /0\.2/ =~ new_version
  new_date = Time.now.strftime('%04Y-%02m-%02d')
  gemspec_re = /version\s+=\s+'([^']*)'$/
  gemspec = File.open('skyed.gemspec').read
  current = gemspec.match(gemspec_re)[1]
  fail 'Update your CHANGELOG first, please' if current == new_version
  repo = Git.open('.')
  fail "Switch to #{skyed_branch} and merge" unless repo.current_branch == skyed_branch
  skyed = File.open('lib/skyed.rb').read
  skyed_version_re = /VERSION(\s+)=(\s+).*/
  new_skyed = skyed.gsub(skyed_version_re, "VERSION\\1=\\2'#{new_version}'")
  gspec_version_re = /version(\s+)=(\s+).*/
  new_gemspec = gemspec.gsub(gspec_version_re, "version\\1=\\2'#{new_version}'")
  date_re = /date(\s+)=(\s+)'.*'/
  new_gemspec = new_gemspec.gsub(date_re, "date\\1=\\2'#{new_date}'")
  date_re = /## #{new_version} .*/
  new_changelog = changelog.gsub(date_re, "## #{new_version} (#{new_date})")
  puts "Updating CHANGELOG: #{new_changelog.lines.first}"
  File.open('CHANGELOG.md', 'w') { |f| f.puts new_changelog } unless ENV['FAKE']
  puts "Updating lib/skyed.rb: #{new_skyed.match(skyed_version_re)}"
  File.open('lib/skyed.rb', 'w') { |f| f.puts new_skyed } unless ENV['FAKE']
  puts "Updating gemspec: #{new_gemspec.match(gspec_version_re)}"
  File.open('skyed.gemspec', 'w') { |f| f.puts new_gemspec } unless ENV['FAKE']
  unless ENV['FAKE']
    repo.add('lib/skyed.rb')
    repo.add('skyed.gemspec')
    repo.add('CHANGELOG.md')
    repo.commit('Updates gemspec')
  end
  puts 'Tagging'
  repo.add_tag(
    "v#{new_version}",
    a: "v#{new_version}",
    m: "Releasing #{new_version}") unless ENV['FAKE']
  puts 'Pushing'
  repo.push(repo.remote('ifosch'), skyed_branch, tags: true) unless ENV['FAKE']
  build unless ENV['FAKE']
  publish(new_version)
end
