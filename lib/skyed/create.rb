module Skyed
  # This module encapsulates all the create command steps.
  module Create
    class << self
      def execute(_global_options, options, args)
        Skyed::Init.credentials if Skyed::Settings.empty?
        endpoint = create_new(options, args) if args.length == 1
        endpoint = restore_new(options, args) if args.length == 2
        puts endpoint
      end

      def restore_new(options, args)
        Skyed::AWS::RDS.create_instance_from_snapshot(
          args[0],
          args[1],
          options.select { |k| k != :rds })
      end

      def create_new(options, args)
        Skyed::AWS::RDS.create_instance(
          args[0],
          options.select { |k| k != :rds })
      end
    end
  end
end
