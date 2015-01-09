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

    def self.get_repo(agree = '.', ask = true)
      repo = repo?(agree)
      if !repo
        repo = another_repo(agree)
      elsif ask
        repo = confirm_repo(repo)
      end
      repo
    end

    def another_repo(agree)
      say("ERROR: #{agree} is not a repository")
      agree = ask('Which is your CM repository? ')
      get_repo(agree, false)
    end

    def confirm_repo(repo)
      agree = ask('Confirm this is your CM repository? ') do |q|
        q.default = repo_path(repo).to_s
      end
      get_repo(agree) if agree != repo_path(repo).to_s
    end

    def self.another_repo(agree)
      say("ERROR: #{agree} is not a repository")
      agree = ask('Which is your CM repository? ')
      get_repo(agree, false)
    end

    def self.confirm_repo(repo)
      agree = ask('Enter your CM repository? ') do |q|
        q.default = repo_path(repo).to_s
      end
      get_repo(agree, false)
    end

    def self.repo?(path)
      Git.open(path)
    rescue ArgumentError
      return false
    end
  end
end
