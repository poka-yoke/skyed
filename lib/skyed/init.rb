require 'git'
require 'aws-sdk'
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

    def self.vagrant
      `which ansible`
      pip_install 'ansible' unless $CHILD_STATUS.success?
    end

    def self.pip_install(package)
      `which pip`
      easy_install 'pip' unless $CHILD_STATUS.success?
      `pip install #{package}`
      fail "Can't install #{package}" unless $CHILD_STATUS.success?
    end

    def self.easy_install(package)
      `easy_install package`
      fail "Can't install #{package}" unless $CHILD_STATUS.success?
    end

    def self.branch
      branch = "devel-#{Digest::SHA1.hexdigest Skyed::Settings.repo}"
      repo = repo?(Skyed::Settings.repo)
      repo.branch(branch).checkout
      branch
    end

    def self.credentials(
      access = ENV['AWS_ACCESS_KEY'],
      secret = ENV['AWS_SECRET_KEY'])
      access_question = 'What is your AWS Access Key? '
      access = ask(access_question) unless valid_credential?('AWS_ACCESS_KEY')
      secret_question = 'What is your AWS Secret Key? '
      secret = ask(secret_question) unless valid_credential?('AWS_SECRET_KEY')
      AWS::OpsWorks.new(
        access_key_id: access,
        secret_access_key: secret)
      [access, secret]
    end

    def self.valid_credential?(env_name)
      ENV[env_name] != '' && !ENV[env_name].nil?
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
