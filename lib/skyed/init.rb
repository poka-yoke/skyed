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
    class << self
      def execute(global_options, options)
        fail 'Already initialized' unless Skyed::Settings.empty?
        Skyed::Settings.repo = repo_path(get_repo).to_s
        branch global_options, options
        credentials
        opsworks_git_key
        opsworks options
        vagrant
        Skyed::Settings.save
      end

      def opsworks(options = {})
        opsworks = Skyed::AWS::OpsWorks.login
        params = Skyed::AWS::OpsWorks.generate_params nil, options
        check_stack(opsworks, params[:name])
        Skyed::AWS::OpsWorks.create_stack(params, opsworks)
        params = Skyed::AWS::OpsWorks.generate_params(Skyed::Settings.stack_id)
        Skyed::AWS::OpsWorks.create_layer(params, opsworks)
      end

      def check_stack(ow, name)
        stack = Skyed::AWS::OpsWorks.stack_summary_by_name(name, ow)
        Skyed::AWS::OpsWorks.delete_stack(stack[:name], ow) unless stack.nil?
        File.delete(vagrantfile) if File.exist?(vagrantfile)
      end

      def vagrantfile
        File.join(Skyed::Settings.repo, 'Vagrantfile')
      end

      def create_vagrant_files
        provisioning_path = File.join(Skyed::Settings.repo, '.provisioning')
        tasks_path = File.join(provisioning_path, 'tasks')
        aws_path = File.join(provisioning_path, 'templates', 'aws')
        Skyed::Utils.create_template(Skyed::Settings.repo, 'Vagrantfile',
                                     'Vagrantfile.erb')
        Skyed::Utils.create_template(tasks_path, 'ow-on-premise.yml',
                                     'ow-on-premise.yml.erb')
        Skyed::Utils.create_template(aws_path, 'config.j2', 'config.j2.erb')
        Skyed::Utils.create_template(aws_path, 'credentials.j2',
                                     'credentials.j2.erb')
      end

      def vagrant
        return if File.exist?(vagrantfile)
        pip_install 'ansible'
        create_directory(Skyed::Settings.repo, '.provisioning/templates/aws')
        create_directory(Skyed::Settings.repo, '.provisioning/tasks')
        create_vagrant_files
      end

      def create_directory(base, subpath)
        folders = subpath.split('/')
        new_dir = File.join(base, folders)
        FileUtils.mkdir_p(new_dir)
      end

      def pip_install(package)
        `pip list | grep #{package}`
        return if $CHILD_STATUS.success?
        `which pip`
        easy_install 'pip' unless $CHILD_STATUS.success?
        `sudo pip install #{package}`
        fail "Can't install #{package}" unless $CHILD_STATUS.success?
      end

      def easy_install(package)
        `easy_install #{package}`
        fail "Can't install #{package}" unless $CHILD_STATUS.success?
      end

      def branch(global_options, options)
        branch = "devel-#{Digest::SHA1.hexdigest Skyed::Settings.repo}"
        repo = repo?(Skyed::Settings.repo)
        repo.branch(branch).checkout
        Skyed::Settings.branch = branch
        remote_data = git_remote_data(repo, global_options, options)
        Skyed::Settings.remote_name = remote_data[:name]
        Skyed::Settings.remote_url = remote_data[:url]
      end

      def git_remote_data(repo, _global_options, options = {})
        name ||= options[:remote]
        name = ask_remote_name(
          repo.remotes.map(&:name)) if repo.remotes.length > 1 && name.nil?
        name = repo.remotes[0].name if name.nil?
        select_remote(name, repo.remotes)
      end

      def select_remote(name, remotes)
        url = nil
        remotes.each do |remote|
          url = remote.url if remote.name == name
        end
        if url.nil?
          { name: remotes[0].name, url: remotes[0].url }
        else
          { name: name, url: url }
        end
      end

      def ask_remote_name(remotes_names)
        question = 'Which remote should be used for the git repository? '
        ask(question + remotes_names.to_s)
      end

      def opsworks_git_key
        question = 'Which ssh key should be used for the git repository? '
        Skyed::Settings.opsworks_git_key = ask(question)
      end

      def credentials(
        access       = ENV['AWS_ACCESS_KEY'],
        secret       = ENV['AWS_SECRET_KEY'],
        role_arn     = ENV['OW_SERVICE_ROLE'],
        profile_arn  = ENV['OW_INSTANCE_PROFILE'],
        aws_key_name = ENV['AWS_SSH_KEY_NAME'])
        Skyed::AWS.set_credentials(access, secret)
        Skyed::AWS::OpsWorks.set_arns(profile_arn, role_arn)
        Skyed::Settings.aws_key_name = aws_key_name
      end

      def repo_path(repo)
        Pathname.new(repo.repo.path).dirname
      end

      def get_repo(path = '.', ask = true)
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

      def repo?(path)
        ::Git.open(path)
      rescue ArgumentError
        return false
      end
    end
  end
end
