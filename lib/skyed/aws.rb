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
