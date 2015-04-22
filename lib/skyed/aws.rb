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

      class << self
        def read_key_file(key_file)
          File.open(key_file, 'rb').read
        end

        def custom_cookbooks_source(base_source)
          base_source[:url] = Skyed::Settings.remote_url
          base_source[:revision] = Skyed::Settings.branch
          base_source[:ssh_key] = read_key_file(
            Skyed::Settings.opsworks_git_key)
          base_source
        end

        def generate_params
          params = STACK
          params[:name] = ENV['USER']
          params[:region] = Skyed::AWS.region
          params[:service_role_arn] = Skyed::Settings.role_arn
          params[:default_instance_profile_arn] = Skyed::Settings.profile_arn
          params[:default_ssh_key_name] = Skyed::Settings.aws_key_name
          params[:custom_cookbooks_source] = custom_cookbooks_source(
            STACK[:custom_cookbooks_source])
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
