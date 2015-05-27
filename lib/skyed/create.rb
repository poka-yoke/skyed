module Skyed
  # This module encapsulates all the create command steps.
  module Create
    class << self
      def execute(_global_options, options, args)
        Skyed::Init.credentials if Skyed::Settings.empty?
        endpoint = Skyed::AWS::RDS.create_instance(
          args[0],
          options.select { |k| k != :rds })
        puts endpoint
      end
    end
  end
end
