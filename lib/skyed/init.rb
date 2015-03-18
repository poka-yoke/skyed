require 'English'
require 'fileutils'
require 'erb'
require 'git'
require 'aws-sdk'
require 'highline/import'
require 'digest/sha1'

ACCESS_QUESTION = 'What is your AWS Access Key? '
SECRET_QUESTION = 'What is your AWS Secret Key? '

STACK = { name: '',
          region: '',
          service_role_arn: '',
          default_instance_profile_arn: '',
          default_os: 'Ubuntu 12.04 LTS',
          default_ssh_key_name: '',
          custom_cookbooks_source: {
            type: 'git'
          },
          configuration_manager: {
            name: 'Chef',
            version: '11.10'
          },
          use_custom_cookbooks: true,
          use_opsworks_security_groups: false
        }

module Skyed
  # This module encapsulates all the init command steps.
  module Init
    def self.execute(_global_options)
      fail 'Already initialized' unless Skyed::Settings.empty?
      Skyed::Settings.repo = repo_path(get_repo).to_s
      branch
      credentials
      opsworks_git_key
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
        shortname: "test-#{ENV['USER']}",
        custom_security_group_ids: ['sg-f1cc2498'] }
    end

    def self.stack_params
      # TODO: Include extra stack parameters
      result = STACK
      result[:name]                         = ENV['USER']
      result[:region]                       = region
      result[:service_role_arn]             = Skyed::Settings.role_arn
      result[:default_instance_profile_arn] = Skyed::Settings.profile_arn
      result[:default_ssh_key_name]         = Skyed::Settings.aws_key_name
      result[:custom_cookbooks_source]      = custom_cookbooks_source(
        STACK[:custom_cookbooks_source])
      result
    end

    def self.custom_cookbooks_source(base_source)
      base_source[:url] = Skyed::Settings.git_url
      base_source[:revision] = Skyed::Settings.branch
      base_source[:ssh_key] = read_key_file(Skyed::Settings.opsworks_git_key)
      base_source
    end

    def self.read_key_file(key_file)
      File.open(key_file, 'rb').read
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

    def self.create_vagrant_files
      provisioning_path = File.join(Skyed::Settings.repo, '.provisioning')
      tasks_path = File.join(provisioning_path, 'tasks')
      aws_path = File.join(provisioning_path, 'templates', 'aws')
      create_template(Skyed::Settings.repo, 'Vagrantfile',
                      'templates/Vagrantfile.erb')
      create_template(tasks_path, 'ow-on-premise.yml',
                      'templates/ow-on-premise.yml.erb')
      create_template(aws_path, 'config.j2', 'templates/config.j2.erb')
      create_template(aws_path, 'credentials.j2',
                      'templates/credentials.j2.erb')
    end

    def self.vagrant
      unless File.exist?(vagrantfile)
        pip_install 'ansible'
        create_directory(Skyed::Settings.repo, '.provisioning/templates/aws')
        create_directory(Skyed::Settings.repo, '.provisioning/tasks')
        create_vagrant_files
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
      Skyed::Settings.branch = branch
      Skyed::Settings.git_url = repo.remotes[0].url
    end

    def self.opsworks_git_key
      question = 'Which ssh key should be used for the git repository? '
      Skyed::Settings.opsworks_git_key = ask(question)
    end

    def self.credentials(
      access       = ENV['AWS_ACCESS_KEY'],
      secret       = ENV['AWS_SECRET_KEY'],
      role_arn     = ENV['OW_SERVICE_ROLE'],
      profile_arn  = ENV['OW_INSTANCE_PROFILE'],
      aws_key_name = ENV['AWS_SSH_KEY_NAME'])
      aws_access_key(access, secret)
      Skyed::Settings.role_arn     = role_arn
      Skyed::Settings.profile_arn  = profile_arn
      Skyed::Settings.aws_key_name = aws_key_name
    end

    def self.aws_access_key(access, secret)
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
