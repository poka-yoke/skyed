require 'aws-sdk'
require 'highline/import'

ACCESS_QUESTION = 'What is your AWS Access Key? '
SECRET_QUESTION = 'What is your AWS Secret Key? '

module Skyed
  # This module encapsulates all the AWS related functions.
  module AWS
    class << self
      def set_credentials(access, secret, force_question = false)
        access = ask(ACCESS_QUESTION) unless Skyed::AWS.valid_credential?(
          'AWS_ACCESS_KEY') || force_question
        secret = ask(SECRET_QUESTION) unless Skyed::AWS.valid_credential?(
          'AWS_SECRET_KEY') || force_question
        if Skyed::AWS.confirm_credentials?(access, secret)
          Skyed::Settings.access_key = access
          Skyed::Settings.secret_key = secret
        else
          set_credentials(access, secret, true)
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
      class << self
        def login(
          access = Skyed::Settings.access_key,
          secret = Skyed::Settings.secret_key,
          region = ENV['AWS_REGION'])
          region ||= 'us-east-1'
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
          region = ENV['AWS_REGION'])
          region ||= 'us-east-1'
          Aws::IAM::Client.new(
            access_key_id: access,
            secret_access_key: secret,
            region: region)
        end
      end
    end
  end
end
