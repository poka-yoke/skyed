require 'git'
require 'highline/import'
require 'digest/sha1'

module Skyed
  # This module encapsulates all the init command steps.
  module Init
    def self.execute(global_options)
      fail 'Already initialized' unless Skyed::Settings.empty?
      puts 'Initializing...' unless global_options[:quiet]
      repo = get_repo
      Skyed::Settings.repo = repo_path(repo).to_s
      branch = "devel-#{Digest::SHA1.hexdigest Skyed::Settings.repo}"
      repo.branch(branch).checkout
      Skyed::Settings.branch = branch
      Skyed::Settings.save
    end

    def self.repo_path(repo)
      Pathname.new(repo.repo.path).dirname
    end

    def self.get_repo(path = '.', ask = true)
      question = 'Which is your CM repository? '
      repo = repo?(path)
      if !repo
        say("ERROR: #{path} is not a repository")
        repo = get_repo(ask(question), false)
      elsif ask
        repo = get_repo(
          ask(question) { |q| q.default = repo_path(repo).to_s }, false)
      end
      repo
    end

    def self.repo?(path)
      Git.open(path)
    rescue ArgumentError
      return false
    end
  end
end
