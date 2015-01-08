require 'git'
require 'highline/import'
require 'digest/sha1'

module Skyed
  module Init
    extend self

    def execute(global_options)
      fail "Already initialized" unless Skyed::Settings.empty?
      puts 'Initializing...' if !global_options[:quiet]
      repo = get_repo()
      Skyed::Settings.repo = repo_path(repo).to_s
      branch = "devel-#{Digest::SHA1.hexdigest Skyed::Settings.repo}"
      repo.branch(branch).checkout
      Skyed::Settings.branch = branch
      Skyed::Settings.save
    end

    def repo_path(repo)
      Pathname.new(repo.repo.path).dirname
    end

    def get_repo(agree = '.', ask = true)
      repo = is_repo(agree)
      if not repo then
        say("ERROR: #{agree} is not a repository")
        agree = ask("Which is your CM repository? ")
        repo = get_repo(agree, false)
      elsif ask then
        agree = ask("Confirm this is your CM repository? ") { |q| q.default = repo_path(repo).to_s }
        repo = get_repo(agree) if agree != repo_path(repo).to_s
      end
      repo
    end

    def is_repo(path)
      Git.open(path)
    rescue ArgumentError
      return false
    end
  end
end
