require 'English'
require 'fileutils'
require 'erb'
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
      # Setup Opsworks environment (Stack and Layer)
      vagrant
      Skyed::Settings.save
    end

    def self.vagrantfile
      File.join(Skyed::Settings.repo, 'Vagrantfile')
    end

    def self.vagrant
      unless File.exist?(vagrantfile)
        pip_install 'ansible'
        create_directory(Skyed::Settings.repo, '.provisioning/templates/aws')
        create_directory(Skyed::Settings.repo, '.provisioning/tasks')
        create_template(
          Skyed::Settings.repo,
          'Vagrantfile',
          'templates/Vagrantfile.erb')
        # TODO: Create ansible playbook
      end
    end

    def self.create_template(base, subpath, template_file)
      folders = subpath.split('/')
      template = ERB.new(
        File.read(
          File.join(
            File.dirname(File.dirname(File.dirname(__FILE__))),
            template_file)))
      File.open(File.join(base, folders), 'w') do |f|
        f.write(template.result)
      end
    end

    def self.create_directory(base, subpath)
      folders = subpath.split('/')
      new_dir = File.join(base, folders)
      FileUtils.mkdir_p(new_dir)
    end

    def self.pip_install(package)
      `pip list | grep #{package}`
      unless $CHILD_STATUS.success?
        `which pip`
        easy_install 'pip' unless $CHILD_STATUS.success?
        `sudo pip install #{package}`
        fail "Can't install #{package}" unless $CHILD_STATUS.success?
      end
    end

    def self.easy_install(package)
      `easy_install #{package}`
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
