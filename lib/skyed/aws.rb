require 'aws-sdk'

module Skyed
  # This module encapsulates all the AWS related functions.
  module AWS
    class << self
      def valid_credential?(env_var_name)
        ENV[env_var_name] != '' && !ENV[env_var_name].nil?
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
