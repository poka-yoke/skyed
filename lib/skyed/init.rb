require 'English'
require 'fileutils'
require 'erb'
require 'git'
require 'aws-sdk'
require 'highline/import'
require 'digest/sha1'

ACCESS_QUESTION = 'What is your AWS Access Key? '
SECRET_QUESTION = 'What is your AWS Secret Key? '

SRA = 'arn:aws:iam::406396564037:role/aws-opsworks-service-role'
IPA = 'arn:aws:iam::406396564037:instance-profile/aws-opsworks-ec2-role'

module Skyed
  # This module encapsulates all the init command steps.
  module Init
    def self.execute(_global_options)
      fail 'Already initialized' unless Skyed::Settings.empty?
      Skyed::Settings.repo = repo_path(get_repo).to_s
      Skyed::Settings.branch = branch
      credentials
      opsworks
      vagrant
      Skyed::Settings.save
    end

    def self.opsworks
      opsworks = ow_client
      stack = opsworks.create_stack(stack_params).data[:stack_id]
      Skyed::Settings.stack_id = stack
      Skyed::Settings.layer_id = opsworks.create_layer(
        layer_params(stack)).data[:layer_id]
    end

    def self.layer_params(stack_id)
      # TODO: Include extra layer parameters
      { stack_id: stack_id,
        type: 'custom',
        name: "test-#{ENV['USER']}",
        shortname: "test-#{ENV['USER']}" }
    end

    def self.stack_params
      # TODO: Include extra stack parameters
      { name: ENV['USER'],
        region: region,
        service_role_arn: Skyed::Settings.service_role,
        default_instance_profile_arn: Skyed::Settings.instance_profile }
    end

    def self.region
      ENV['DEFAULT_REGION'] || 'us-east-1'
    end

    def self.ow_client(
      access = Skyed::Settings.access_key,
      secret = Skyed::Settings.secret_key)
      AWS::OpsWorks::Client.new(
        access_key_id: access,
        secret_access_key: secret)
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
      b = binding
      folders = subpath.split('/')
      template = ERB.new(
        File.read(
          File.join(
            File.dirname(File.dirname(File.dirname(__FILE__))),
            template_file)))
      File.open(File.join(base, folders), 'w') do |f|
        f.write(template.result b)
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
      # TODO: Generalize these two settings
      Skyed::Settings.service_role = SRA
      Skyed::Settings.instance_profile = IPA
      access = ask(ACCESS_QUESTION) unless valid_credential?('AWS_ACCESS_KEY')
      secret = ask(SECRET_QUESTION) unless valid_credential?('AWS_SECRET_KEY')
      ow_client(access, secret)
      Skyed::Settings.access_key = access
      Skyed::Settings.secret_key = secret
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
