module Skyed
  # This module encapsulates all the create command steps.
  module Create
    @non_rds_options = [:rds, :stack, :layer]
    class << self
      def execute(_global_options, options, args)
        Skyed::Init.credentials if Skyed::Settings.empty?
        execute_rds(options, args) if options[:rds]
        create_opsworks(options, args) unless options[:rds]
      end

      def check_create_options(options)
        msg = 'Specify stack and layer or initialize for local management'
        fail msg unless options[:stack] && options[:layer]
      end

      def create_opsworks(options, _args)
        check_create_options(options)
        ow = login
        stack_id = stack(ow, options)
        layer_id = layer(ow, options)
        Skyed::AWS::OpsWorks.create_instance(
          stack_id, layer_id, options[:type], ow)
      end

      def stack(ow, options)
        stack = Skyed::AWS::OpsWorks.stack(options[:stack], ow)
        msg = "There's no such stack with id #{options[:stack]}"
        fail msg unless stack
        stack[:stack_id]
      end

      def layer(ow, options)
        layer = Skyed::AWS::OpsWorks.layer(options[:layer], ow)
        msg = "There's no such layer with id #{options[:layer]}"
        fail msg unless layer
        layer[:layer_id]
      end

      def execute_rds(options, args)
        endpoint = create_new(options, args) if args.length == 1
        endpoint = restore_new(options, args) if args.length == 2
        puts endpoint
      end

      def restore_new(options, args)
        Skyed::AWS::RDS.create_instance_from_snapshot(
          args[0],
          args[1],
          options.select { |k| ! @non_rds_options.include? k })
      end

      def create_new(options, args)
        Skyed::AWS::RDS.create_instance(
          args[0],
          options.select { |k| ! @non_rds_options.include? k })
      end

      def login
        Skyed::Init.credentials if Skyed::Settings.empty?
        Skyed::AWS::OpsWorks.login
      end
    end
  end
end
