require 'aws-sdk'
require 'highline/import'

ACCESS_QUESTION = 'What is your AWS Access Key? '
SECRET_QUESTION = 'What is your AWS Secret Key? '

module Skyed
  # This module encapsulates all the AWS related functions.
  module AWS
    class << self
      def region
        ENV['AWS_DEFAULT_REGION'] || 'us-east-1'
      end

      def set_credentials(access, secret, skip_question = true)
        access = ask(ACCESS_QUESTION) unless Skyed::AWS.valid_credential?(
          'AWS_ACCESS_KEY') && skip_question
        secret = ask(SECRET_QUESTION) unless Skyed::AWS.valid_credential?(
          'AWS_SECRET_KEY') && skip_question
        if Skyed::AWS.confirm_credentials?(access, secret)
          Skyed::Settings.access_key = access
          Skyed::Settings.secret_key = secret
        else
          set_credentials(access, secret, false)
        end
      end

      def valid_credential?(env_var_name)
        ENV[env_var_name] != '' && !ENV[env_var_name].nil?
      end

      def confirm_credentials?(access, secret)
        client = Skyed::AWS::IAM.login(access, secret)
        client.get_account_summary
        true
      rescue Aws::IAM::Errors::InvalidClientTokenId
        false
      end
    end

    # This module encapsulates all the RDS related functions.
    module RDS
      class << self
        def create_instance_from_snapshot(
          instance_name,
          snapshot,
          _options,
          rds = nil)
          rds = login if rds.nil?
          rds.restore_db_instance_from_db_snapshot(
            db_instance_identifier: instance_name,
            db_snapshot_identifier: snapshot)[:db_instance]
          db_instance = wait_for_instance(instance_name, 'available', 0, rds)
          "#{db_instance[:endpoint][:address]}:#{db_instance[:endpoint][:port]}"
        end

        def list_snapshots(_options, args, rds = nil)
          rds = login if rds.nil?
          request = {}
          request[:db_instance_identifier] = args.first unless args.nil?
          response = rds.describe_db_snapshots(request)
          response.db_snapshots
        end

        def destroy_instance(instance_name, options, rds = nil)
          rds = login if rds.nil?
          rds.delete_db_instance(
            generate_params(instance_name, options))[:db_instance]
        end

        def generate_delete_params(instance_name, options)
          snapshot = !options[:final_snapshot_name].empty?
          params = {
            db_instance_identifier: instance_name,
            skip_final_snapshot: !snapshot
          }
          params[
            :final_snapshot_name] = options[:final_snapshot_name] if snapshot
          params
        end

        def generate_create_params(instance_name, options)
          {
            db_instance_identifier: instance_name,
            allocated_storage: options[:size],
            db_instance_class: "db.#{options[:type]}",
            engine: 'postgres',
            master_username: options[:user],
            master_user_password: options[:password],
            db_security_groups: [options[:db_security_group]],
            db_parameter_group_name: options[:db_parameters_group]
          }
        end

        def wait_for_instance(instance_name, status, wait = 0, rds = nil)
          rds = login if rds.nil?
          instance = rds.describe_db_instances(
            db_instance_identifier: instance_name)[:db_instances][0]
          while instance[:db_instance_status] != status
            sleep(wait)
            instance = rds.describe_db_instances(
              db_instance_identifier: instance_name)[:db_instances][0]
          end
          instance
        end

        def generate_params(instance_name, options)
          params = generate_delete_params(
            instance_name, options) if options.key? :final_snapshot_name
          params = generate_create_params(
            instance_name, options) if options.key? :user
          params
        end

        def create_instance(instance_name, options, rds = nil)
          rds = login if rds.nil?
          rds.create_db_instance(
            generate_params(instance_name, options))[:db_instance]
          db_instance = wait_for_instance(instance_name, 'available', 0, rds)
          "#{db_instance[:endpoint][:address]}:#{db_instance[:endpoint][:port]}"
        end

        def login(
          access = Skyed::Settings.access_key,
          secret = Skyed::Settings.secret_key,
          region = Skyed::AWS.region)
          Aws::RDS::Client.new(
            access_key_id: access,
            secret_access_key: secret,
            region: region)
        end
      end
    end

    # This module encapsulates all the OpsWorks related functions.
    module OpsWorks
      STACK = {
        name: '',
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
      LAYER = {
        stack_id: nil,
        type: 'custom',
        name: '',
        shortname: '',
        custom_security_group_ids: []
      }

      class << self
        def deregister_instance(hostname, opsworks)
          instance = instance_by_name(
            hostname, Skyed::Settings.stack_id, opsworks)
          opsworks.deregister_instance(
            instance_id: instance.instance_id) unless instance.nil?
          wait_for_instance(
            hostname, Skyed::Settings.stack_id, 'terminated', opsworks)
        end

        def delete_user(opsworks)
          stack = opsworks.describe_stacks(
            stack_ids: [Skyed::Settings.stack_id])[:stacks][0][:name]
          layer = opsworks.describe_layers(
            layer_ids: [Skyed::Settings.layer_id])[:layers][0][:name]
          Skyed::AWS::IAM.delete_user "OpsWorks-#{stack}-#{layer}"
        end

        def wait_for_instance(instance_name, stack_id, status, opsworks)
          instance = Skyed::AWS::OpsWorks.instance_by_name(
            instance_name, stack_id, opsworks)
          until instance.nil? || instance.status == status
            sleep(0)
            instance = Skyed::AWS::OpsWorks.instance_by_name(
              instance_name, stack_id, opsworks)
          end
        end

        def stack(stack_criteria, opsworks)
          stack_by_name(
            stack_criteria,
            opsworks
          ) || stack_by_id(stack_criteria, opsworks)
        end

        def layer(layer_criteria, opsworks)
          layer_by_name(
            layer_criteria,
            opsworks
          ) || layer_by_id(layer_criteria, opsworks)
        end

        def deploy(opts)
          xtra = { instance_ids: opts[:instance_ids] }
          xtra[:custom_json] = opts[:custom_json] if opts.key? :custom_json
          Skyed::AWS::OpsWorks.wait_for_deploy(
            opts[:client].create_deployment(
              Skyed::AWS::OpsWorks.generate_deploy_params(
                opts[:stack_id],
                opts[:command],
                xtra)),
            opts[:client],
            opts[:wait_interval])
        end

        def layer_by_id(layer_id, opsworks)
          layers(opsworks).select { |x| x[:layer_id] == layer_id }[0] || nil
        end

        def layer_by_name(layer_name, opsworks)
          layers(opsworks).select { |x| x[:name] == layer_name }[0] || nil
        end

        def layers(opsworks)
          opsworks.describe_layers(stack_id: Skyed::Settings.stack_id)[:layers]
        end

        def stack_by_id(stack_id, opsworks)
          stacks(opsworks).select { |x| x[:stack_id] == stack_id }[0] || nil
        end

        def running_instances(options = {}, opsworks)
          instances = opsworks.describe_instances(options)
          instances[:instances].map do |instance|
            instance[:instance_id] if instance[:status] != 'stopped'
          end.compact
        end

        def instance_by_name(hostname, stack_id, opsworks)
          opsworks.describe_instances(
            stack_id: stack_id)[:instances].select do |i|
            i.hostname == hostname
          end[0]
        end

        def wait_for_deploy(deploy, opsworks, wait = 0)
          status = Skyed::AWS::OpsWorks.deploy_status(deploy, opsworks)
          while status[0] == 'running'
            sleep(wait)
            status = Skyed::AWS::OpsWorks.deploy_status(deploy, opsworks)
          end
          status
        end

        def deploy_status(deploy, opsworks)
          deploy = opsworks.describe_deployments(
            deployment_ids: [deploy[:deployment_id]])
          deploy[:deployments].map do |s|
            s[:status]
          end.compact
        end

        def generate_deploy_params(stack_id, command, options = {})
          options = {} if options.nil?
          params = {
            stack_id: stack_id,
            command: generate_command_params(command)
          }
          params.merge(options)
        end

        def generate_command_params(options = {})
          response = options
          response = {
            name: options[:name],
            args: options.reject { |k, _v| k == :name }
          } unless options[:name] != 'execute_recipes'
          response
        end

        def create_layer(layer_params, opsworks)
          layer = opsworks.create_layer(layer_params)
          Skyed::Settings.layer_id = layer.data[:layer_id]
        end

        def create_stack(stack_params, opsworks)
          stack = opsworks.create_stack(stack_params)
          Skyed::Settings.stack_id = stack.data[:stack_id]
        end

        def delete_stack(stack_name, opsworks)
          total = count_instances(stack_name, opsworks)
          error_msg = "Stack with name #{stack_name}"
          error_msg += ' exists and contains instances'
          fail error_msg unless total == 0
          stack = stack_by_name(stack_name, opsworks)
          opsworks.delete_stack(stack_id: stack[:stack_id])
        end

        def count_instances(stack_name, opsworks)
          stack_summary = stack_summary_by_name(stack_name, opsworks)
          return nil if stack_summary.nil?
          total = stack_summary[:instances_count].values.compact.inject(:+) || 0
          total
        end

        def stack_summary_by_name(stack_name, opsworks)
          stack = stack_by_name(stack_name, opsworks)
          opsworks.describe_stack_summary(
            stack_id: stack[:stack_id])[:stack_summary] unless stack.nil?
        end

        def stack_by_name(stack_name, opsworks)
          stacks(opsworks).select { |x| x[:name] == stack_name }[0] || nil
        end

        def stacks(opsworks)
          opsworks.describe_stacks[:stacks]
        end

        def basic_stack_params
          params = STACK
          params[:name] = ENV['USER']
          params[:region] = Skyed::AWS.region
          params[:service_role_arn] = Skyed::Settings.role_arn
          params[:default_instance_profile_arn] = Skyed::Settings.profile_arn
          params[:default_ssh_key_name] = Skyed::Settings.aws_key_name
          params
        end

        def custom_cookbooks_source(base_source)
          base_source[:url] = Skyed::Settings.remote_url
          base_source[:revision] = Skyed::Settings.branch
          base_source[:ssh_key] = Skyed::Utils.read_key_file(
            Skyed::Settings.opsworks_git_key)
          base_source
        end

        def configuration_manager(base_config, options)
          base_config[:name] = 'Chef'
          base_config[:version] = options[:chef_version] || '11.10'
          base_config
        end

        def generate_params(stack_id = nil, options = {})
          params = generate_layer_params(stack_id) unless stack_id.nil?
          params = generate_stack_params(options) if stack_id.nil?
          params
        end

        def generate_layer_params(stack_id)
          params = LAYER
          params[:stack_id] = stack_id
          params[:name] = "test-#{ENV['USER']}"
          params[:shortname] = "test-#{ENV['USER']}"
          params[:custom_security_group_ids] = ['sg-f1cc2498']
          params
        end

        def generate_stack_params(options)
          params = basic_stack_params
          params[:custom_json] = options[:custom_json] || ''
          params[:custom_cookbooks_source] = custom_cookbooks_source(
            STACK[:custom_cookbooks_source])
          params[:configuration_manager] = configuration_manager(
            STACK[:configuration_manager], options)
          params
        end

        def login(
          access = Skyed::Settings.access_key,
          secret = Skyed::Settings.secret_key,
          region = Skyed::AWS.region)
          Aws::OpsWorks::Client.new(
            access_key_id: access,
            secret_access_key: secret,
            region: region)
        end

        def set_arns(service_role = nil, instance_profile = nil)
          iam = Skyed::AWS::IAM.login
          Skyed::Settings.role_arn = service_role || iam.get_role(
            role_name: 'aws-opsworks-service-role')[:role][:arn]
          Skyed::Settings.profile_arn = instance_profile || iam
            .get_instance_profile(
              instance_profile_name: 'aws-opsworks-ec2-role'
            )[:instance_profile][:arn]
        end
      end
    end

    # This module encapsulates all the IAM related functions.
    module IAM
      class << self
        def remove_user_from_group(user, group)
          iam = login
          puts "Removes #{user} from #{group}"
          iam.remove_user_from_group(
            group_name: group,
            user_name: user)
        rescue Aws::IAM::Errors::NoSuchEntity
          puts "User #{user} already removed from group #{group}"
        end

        def clear_user_access_keys(user)
          iam = login
          iam.list_access_keys(
            user_name: user)[:access_key_metadata].each do |access_key|
            id = access_key.to_h[:access_key_id]
            puts "Delete access key #{id}"
            iam.delete_access_key(user_name: user, access_key_id: id)
          end
        rescue Aws::IAM::Errors::NoSuchEntity
          puts "User #{user} access keys already removed"
        end

        def clear_user_policies(user)
          iam = login
          iam.list_user_policies(
            user_name: user)[:policy_names].each do |policy|
            puts "Delete user policy #{policy}"
            iam.delete_user_policy(user_name: user, policy_name: policy)
          end
        rescue Aws::IAM::Errors::NoSuchEntity
          puts "User #{user} policies already removed"
        end

        def delete_user(user)
          iam = login
          clear_user_policies user
          clear_user_access_keys user
          remove_user_from_group user, "OpsWorks-#{Skyed::Settings.stack_id}"
          puts "Delete group OpsWorks-#{Skyed::Settings.stack_id}"
          iam.delete_group(group_name: "OpsWorks-#{Skyed::Settings.stack_id}")
          puts "Delete User #{user}"
          iam.delete_user(user_name: user)
        rescue Aws::IAM::Errors::NoSuchEntity
          puts "User #{user} already removed"
        end

        def login(
          access = Skyed::Settings.access_key,
          secret = Skyed::Settings.secret_key,
          region = Skyed::AWS.region)
          Aws::IAM::Client.new(
            access_key_id: access,
            secret_access_key: secret,
            region: region)
        end
      end
    end
  end
end
