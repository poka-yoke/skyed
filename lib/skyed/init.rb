require 'git'
require 'highline/import'
require 'digest/sha1'

module Skyed
  # This module encapsulates all the init command steps.
  module Init
    def self.execute(_global_options)
      fail 'Already initialized' unless Skyed::Settings.empty?
      Skyed::Settings.repo = repo_path(get_repo).to_s
      Skyed::Settings.branch = branch
      Skyed::Settings.access_key, Skyed::Settings.secret_key = credentials
      Skyed::Settings.save
    end

    def self.branch
      branch = "devel-#{Digest::SHA1.hexdigest Skyed::Settings.repo}"
      repo = repo?(Skyed::Settings.repo)
      repo.branch(branch).checkout
      branch
    end

    def self.credentials
      access_question = 'What is your AWS Access Key? '
      access = ENV['AWS_ACCESS_KEY']
      access = ask(access_question) if ENV['AWS_ACCESS_KEY'] == ''
      secret_question = 'What is your AWS Secret Key? '
      secret = ENV['AWS_SECRET_KEY']
      secret = ask(secret_question) if ENV['AWS_SECRET_KEY'] == ''
      [access, secret]
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
